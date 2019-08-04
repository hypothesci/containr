# containr
containr is designed to package up an R project inside a Docker container, including all of its dependencies.

## Usage
The main function in this package is `docker_deploy`, which takes care of building, tagging, and pushing an image to a remote Docker registry such as Docker Hub or the AWS Elastic Container Registry.

```r
# push to Docker Hub
containr::docker_deploy("yourcompany/my-project-image:latest")

# push to ECR
containr::docker_deploy("12345.dkr.ecr.us-east-1.amazonaws.com/my-project-image:latest")
```

If you need extra system-level dependencies (e.g. `RPostgreSQL` users will need `libpq-dev` installed), simply use the `system_deps` argument:

```r
containr::docker_deploy("yourcompany/my-project-image:latest", system_deps = c("libpq-dev"))
```

## Image details
Currently, all images are based on Ubuntu 16.04 LTS (Xenial). As this is quite a large base image, it would be ideal to find something smaller that still allows for installation of most R packages (from source).
