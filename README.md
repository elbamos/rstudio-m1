
## Dockerfile for RStudio Server on ARM

This is a Dockerfile for running RStudio Server on Apple Silicon (M1) processors.

It is based on [`edgyr`](https://github.com/edgyR/edgyR-containers) and [`Rocker`](https://github.com/rocker-org/rocker-versioned).

This is available from [Docker Hub](https://hub.docker.com/repository/docker/amoselb/rstudio-m1) and can be run as a Rocker with `docker run -d -p 8787:8787 -v ~/Projects/:/home/rstudio/projects -e PASSWORD=YOURPASSWORD amoselb/rstudio-m1`

I do not claim this to be a good Docker build. It is larger than I would like, and based on an older version of the `Rocker` scripts. It does, however, serve the limited purpose of getting RStudio running with a native build on R on Apple M1 laptops. It can hopefully help tide us over until [RStudio Client is native on M1](https://github.com/rstudio/rstudio/issues/8652). PRs are welcome!  
