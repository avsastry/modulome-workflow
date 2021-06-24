# Make sure to start with a .dockerignore file that contains at least .git (see file in this repo)
# To build the docker container, run
#
#       docker build . -t <username>/<repo_name>:<version>
#
# Once you've tested the container and are ready to publish, run
#
#       docker push <username>/<repo_name>:<version>
#


# Start with PyModulon base container
FROM sbrg/pymodulon:v0.2.1

# Add your contact information
LABEL maintainer="Anand Sastry <avsastry@eng.ucsd.edu>"

# Change to root user for installation
USER root

# Update apt packages (only required if you are installing a new apt package)
RUN apt-get update --yes

# Install R and R dependencies
RUN apt-get install --yes --no-install-recommends software-properties-common \
    gpg-agent dirmngr gfortran liblapack-dev libopenblas-dev && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    apt-get install --yes --no-install-recommends r-base

# Install R libraries
RUN Rscript -e 'install.packages(c("treemap","VennDiagram"))'

# Change user back to NB_USER
USER $NB_USER

# Copy the relevant folders with jupyter notebooks to the container
COPY 3_quality_control /home/${NB_USER}/modulome-workflow/3_quality_control
COPY 5_characterize_iModulons /home/${NB_USER}/modulome-workflow/5_characterize_iModulons
COPY data /home/${NB_USER}/modulome-workflow/data
COPY figures /home/${NB_USER}/modulome-workflow/figures

# Make sure to test your container and ensure that everything runs!
