#!/usr/bin/env nextflow

def helpMessage() {
    log.info"""
    Usage:

    nextflow run main.nf [ARGS]

    Required Arguments:
      --organism            Name of organism
      --metadata            Path to metadata file
      --sequence_dir        Directory containing *.fasta and *.gff3 files

    Optional Arguments:
      --outdir              Directory to place outputs
      --force               Overwrite existing processed data

    """.stripIndent()
}

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

if ( params.organism == "None" ) {
    log.info"""
    Missing required argument --organism
    """.stripIndent()

    helpMessage()
    exit 0
}

if ( params.metadata == "None" ) {
    log.info"""
    Missing required argument --metadata
    """.stripIndent()

    helpMessage()
    exit 0
}

if ( params.sequence_dir == "None" ) {
    log.info"""
    Missing required argument --sequence_dir
    """.stripIndent()

    helpMessage()
    exit 0
}

@Grab('com.xlson.groovycsv:groovycsv:1.3')
import static com.xlson.groovycsv.CsvParser.parseCsv

// ********************************
// * Step 1: Process genome files *
// ********************************

// Read in fasta and gff file for genome and plasmids (if any)
Channel
    .fromFilePairs("${params.sequence_dir}/*.{fasta,gff3}", checkIfExists:true)
    .into{ genome_ch1; genome_ch2 }

// Isolate fasta files for bowtie
genome_ch1
    .flatten()
    .filter(~/.*\.fasta$/)
    .set{ fasta_ch }

// Isolate GFF files for featureCounts
genome_ch2
    .flatten()
    .filter(~/.*\.gff3$/)
    .tap{ gff_ch }
    // Save only one gff for strand inference
    .first()
    .set{ bedtools_gff_ch }

// Build bowtie index

process bowtie_build {

    label 'bowtie'
    label 'small'

    input:
    file(fasta) from fasta_ch.collect()

    output:
    file('index*') into index_ch
    file('cspace_index*') into cspace_index_ch

    script:
    full_fasta = "${params.organism}.fasta"
    """
    cat ${fasta} > ${full_fasta}
    bowtie-build --threads ${task.cpus} ${full_fasta} index
    bowtie-build -C --threads ${task.cpus} ${full_fasta} cspace_index
    """

}

// Convert GFF to BED file for strand inference

process gff2bed {

    label 'small'

    input:
    file(gff) from bedtools_gff_ch

    output:
    file('genome.bed') into bed_file_ch

    script:
    """
    gff2bed < ${gff} > genome.bed
    """
}

// *******************************
// * Step 2: Parse metadata file *
// *******************************

// Ensure file exists
File csv = new File(params.metadata)
assert(csv.exists())

// Load metadata file
csv_text = file(params.metadata).text
csv_data = parseCsv(csv_text,separator:'\t')

// Loop through rows
sample_ids = csv_data.collect { row ->

    // Ensure that Layout is either SINGLE or PAIRED
    assert((row['LibraryLayout'] == 'SINGLE') ||
           (row['LibraryLayout'] == 'PAIRED'))

    // Save Experiment ID in sample_ids
    row['Experiment']
}

// Ensure that sample IDs are unique
assert(sample_ids.clone().unique().size() == sample_ids.size())

// Check if results already exist
run_list = []
if (!params.force) {
    if (params.outdir.startsWith('s3://')) {
        // Use AWS CLI to get list of runs already completed
        def sout = new StringBuilder(), serr = new StringBuilder()
        def proc = "aws s3 ls ${params.outdir}/featureCounts/".execute()
        proc.consumeProcessOutput(sout, serr)
        proc.waitForOrKill(10000)

        // Parse AWS CLI output
        def raw_list = "$sout".split('\n')
        for (item in raw_list) {
            match = item =~ ".*\\s(.*)_cds.txt"
            if (match.find()) {
                run_list << match.group(1)
            }
        }
    }

    else {
        dir = new File("${params.outdir}/featureCounts")
        if (dir.exists()) {
            // Loop through results directory and get experiment names
            dir.eachFile {
                if (it.name.endsWith('_cds.txt')) {
                    run_list << it.name.minus('_cds.txt')
                }
            }
        }
    }
}

Channel
    .fromPath(params.metadata,checkIfExists:true)
    .splitCsv(header:true,sep:'\t')
    .filter { row ->
        !run_list.contains(row.Experiment)
    }
    .branch { row ->
        sra: row.R1 == ""
            return tuple(row.Experiment,
                         row.LibraryLayout,
                         row.Platform,
                         row.Run)

        local_paired: row.LibraryLayout == "PAIRED"
            return tuple(row.Experiment,
                         row.LibraryLayout,
                         row.Platform,
                         // Allow for multiple ';'-separated R1/R2 files
                         tuple(row.R1.split(';').collect{ x -> file(x) }),
                         tuple(row.R2.split(';').collect{ x -> file(x) }))


         local_single: row.LibraryLayout == "SINGLE"
            return tuple(row.Experiment,
                         row.LibraryLayout,
                         row.Platform,
                         // Allow for multiple ';'-separated R1 files
                         tuple(row.R1.split(';').collect{ x -> file(x) }))
    }
    .set{ metadata_ch }


// ********************************************
// * Step 3: Stage FASTQ files for processing *
// ********************************************

// Download from SRA
process download_fastq {

    maxRetries 1
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    label 'fastq'
    label 'medium'
    label 'stage'

    input:
    tuple sample_id, layout, platform, run_ids from metadata_ch.sra

    output:
    tuple sample_id, layout, platform, file("${sample_id}_[12].fastq.gz") into sra_output_ch

    script:

    """
    for run in ${run_ids.replace(';',' ')}; do
        prefetch --max-size 1000000000000 \$run
        fasterq-dump \$run -e ${task.cpus}
    done

    if [ "${layout}" = "SINGLE" ]; then
        pigz -c *.fastq > ${sample_id}_1.fastq.gz
    else
        pigz -c *_1.fastq > ${sample_id}_1.fastq.gz
        pigz -c *_2.fastq > ${sample_id}_2.fastq.gz
    fi
    """
}


// Stage local file
process stage_fastq_single {

    label 'fastq'
    label 'medium'
    label 'stage'

    input:
    tuple sample_id, layout, platform, file(R1) from metadata_ch.local_single

    output:
    tuple sample_id, layout, platform, file("${sample_id}_1.fastq.gz") into single_output_ch

    script:
    """
    stage_fastq.sh --name ${sample_id} -r1 "${R1}"
    """
}

process stage_fastq_paired {

    label 'fastq'
    label 'medium'
    label 'stage'

    input:
    tuple sample_id, layout, platform, file(R1),file(R2) from metadata_ch.local_paired

    output:
    tuple sample_id, layout, platform, file("${sample_id}_[12].fastq.gz") into paired_output_ch

    script:
    """
    stage_fastq.sh --name ${sample_id} -r1 "${R1}" -r2 "${R2}"
    """
}

// Combine SRA and local fastq channels
fastq_output_ch = sra_output_ch.mix(single_output_ch).mix(paired_output_ch)

// *****************************
// *  Step 4: Run Trim Galore! *
// *****************************

process trim_galore {

    time '8h'
    maxRetries 2
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    label 'large'
    label 'trim_galore'

    publishDir "${params.outdir}/trim_reports", mode: 'copy', pattern: '*trimming_report.txt'
    publishDir "${params.outdir}/fastqc", mode: 'copy', pattern: '*_fastqc.zip'

    input:
    tuple sample_id, layout, platform, file(fastq) from fastq_output_ch

    output:
    tuple sample_id, layout, platform, file("*.fq.gz") into bowtie_input_ch
    file "*trimming_report.txt" optional true into cutadapt_results_ch
    file "*_fastqc.{zip,html}" into fastqc_results_ch

    script:

    if (platform == 'ABI_SOLID')
        """
        fastqc -f fastq -t ${task.cpus} ${fastq}

        for f in ${fastq}; do
            mv -- "\$f" "\${f%.fastq}.fq.gz"
        done
        """


    if (layout == 'SINGLE')

        """
        trim_galore --cores ${task.cpus} --fastqc --basename ${sample_id} ${fastq}
        """

    else

        """
        trim_galore --cores ${task.cpus} --fastqc --paired --basename ${sample_id} ${fastq}
        """
}

// *********************************
// * Step 5: Align reads to genome *
// *********************************

process bowtie_align {

    maxRetries 3
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    publishDir "${params.outdir}/bowtie", mode: 'copy', pattern: '*_bowtie.txt'

    label 'bowtie'
    label 'large'

    input:
    tuple sample_id, layout, platform, file(fastq) from bowtie_input_ch
    file(index) from index_ch.collect()
    file(cspace_index) from cspace_index_ch.collect()

    output:
    tuple sample_id, layout, platform, file("*.sam") into sam_ch, sam_ch2
    file('*_bowtie.txt') into bowtie_results_ch

    script:

    if ( platform == 'ABI_SOLID' )
        index_arg = "-C cspace_index"
    else
        index_arg = "index"

    if ( layout == 'SINGLE')
        """
        bowtie -X 1000 -3 3 -n 2 -p ${task.cpus} -S ${index_arg} ${fastq} 1> ${sample_id}.sam 2> ${sample_id}_bowtie.txt
        """
    else
        """
        bowtie -X 1000 -3 3 -n 2 -p ${task.cpus} -S ${index_arg} -1 ${fastq[0]} -2 ${fastq[1]} 1> ${sample_id}.sam 2> ${sample_id}_bowtie.txt
        """

}

// ********************************
// * Step 5B: Convert to BAM file *
// ********************************

process sam2bam {

    maxRetries 3
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    label 'large'

    input:
    tuple sample_id,layout,platform,file(samfile) from sam_ch

    output:
    tuple sample_id,layout,platform,file("*.bam") into bam_ch

    script:
    """
    samtools view -b ${samfile} -@ ${task.cpus} -o ${sample_id}.unsorted
    samtools sort ${sample_id}.unsorted -@ ${task.cpus} -o ${sample_id}.bam
    """

}

// ********************************
// * Step 6: Infer read direction *
// ********************************

process get_read_direction {

    maxRetries 3
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    label 'python'
    label 'small'

    publishDir "${params.outdir}/rseqc", mode: 'copy', pattern: '*.infer_experiment.txt'

    input:
    tuple sample_id,layout,platform,file(samfile) from sam_ch2
    file bed_file from bed_file_ch

    output:
    tuple val(sample_id),stdout into direction_ch
    file("*.txt") into rseqc_results_ch

    script:

    """
    infer_experiment.py -r ${bed_file} -i ${samfile} > ${sample_id}.infer_experiment.txt
    parse_direction.py ${sample_id}.infer_experiment.txt ${layout} | tr -d '\n'
    """
}

bam_ch2 = bam_ch.join(direction_ch)

// *****************************
// * Step 6: Run featureCounts *
// *****************************

process featureCounts {

    maxRetries 3
    errorStrategy  { task.attempt <= maxRetries  ? 'retry' : 'ignore' }

    publishDir "${params.outdir}/featureCounts", mode: 'copy', pattern: '*.txt*'
    label 'large'

    input:
    tuple sample_id,layout,platform,file(bam_file),val(orientation) from bam_ch2
    file(gff) from gff_ch.collect()

    output:
    file("*_all.txt.summary") into fc_results_ch
    file("*_cds.txt") into counts_ch

    script:

    if ( layout == 'PAIRED')
        type = '-p -B -C -P'
    else
        type = ''

    args = "${type} --fracOverlap 0.5 -T ${task.cpus} ${orientation} -a all.gff"

    """
    cat ${gff} > all.gff

    featureCounts ${args} \
    -t CDS -g locus_tag \
    -o ${sample_id}_cds.txt \
    ${bam_file}

    featureCounts ${args} \
    -t rRNA -g locus_tag \
    -o ${sample_id}_rRNA.txt \
    ${bam_file}

    merge_summaries.sh ${sample_id}
    """
}

// ****************************
// * Step 7: Compile all data *
// ****************************

multiqc_config_ch = Channel.fromPath(params.multiqc_config,checkIfExists:true)

process multiqc {

    publishDir "${params.outdir}", mode:'copy'
    label 'large'

    input:
    file('fastqc/*') from fastqc_results_ch.collect().ifEmpty([])
    file('cutadapt/*') from cutadapt_results_ch.collect().ifEmpty([])
    file('rseqc/*') from rseqc_results_ch.collect().ifEmpty([])
    file('bowtie/*') from bowtie_results_ch.collect().ifEmpty([])
    file('featureCounts/*') from fc_results_ch.collect().ifEmpty([])
    file(myconfig) from multiqc_config_ch


    output:
    file "multiqc_report.html" into multiqc_report_ch
    file "multiqc_data"
    file "multiqc_stats.tsv"

    script:
    """
    multiqc -f -c ${myconfig} .
    assemble_qc_stats.py multiqc_data
    """
}

process assemble_tpm {

    publishDir "${params.outdir}", mode:'copy'
    label 'python'
    label 'large'

    input:
    file('featureCounts/*') from counts_ch.collect().ifEmpty([])

    output:
    file('log_tpm.csv')

    script:
    """
    assemble_tpm.py -d featureCounts -o .
    """

}
