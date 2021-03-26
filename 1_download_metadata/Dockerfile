FROM ncbi/edirect
MAINTAINER Anand V Sastry <avsastry@ucsd.edu>

# Install python packages
USER root
RUN apt-get update -y && apt-get install -y python3-pip && pip3 install pandas

# Copy scripts
COPY clean_metadata_file.py /usr/local/bin/clean_metadata_file.py
COPY download_metadata.sh /usr/local/bin/download_metadata.sh

# define entry point
ENTRYPOINT ["/usr/local/bin/download_metadata.sh"]
