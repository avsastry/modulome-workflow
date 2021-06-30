# Step 3: Quality Control

This folder contains two Jupyter notebooks outlining five quality control steps. Between the first and second notebooks, you will need to manually curate the experimental metadata to identify which samples are biological/technical replicates.

To run these notebooks, you can either install [Jupyter Notebook](https://jupyter.org/install) and install the dependencies in `requirements.txt`, or use a pre-existing docker container.

## Running the docker container
1. Install [Docker](https://docs.docker.com/get-docker/)
2. Run the following code in terminal
```bash
docker run -p 8888:8888 avsastry/modulome-workflow:v1.0
```
3. Select the third link in terminal (starts with 127.0.0.1)
4. Navigate to the `3_quality_control` folder and open the notebooks. Any changes made are only saved in the container, and not on your local computer.

## Mounting local files in the Docker container
If you want to edit and save files in the docker container, replace the above command with the following:
```bash
docker run -p 8888:8888 -v <current-path>:/home/jovyan/work avsastry/modulome-workflow:v1.0
```
The files in `/home/jovyan/work` are mounted from your local machine. These files are editable, and changes made in the docker container will be reflected on your own machine.

For more options, such as changing the default username, changing the port, or granting root access, see the Jupyter Docker Stacks [Feature page](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html)
