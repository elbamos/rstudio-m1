
## Dockerfile for RStudio Server on ARM

This is a Dockerfile for running RStudio Server on Apple Silicon (M1) processors.

It is based on [`edgyr`](https://github.com/edgyR/edgyR-containers) and [`Rocker`](https://github.com/rocker-org/rocker-versioned).

I do not claim this to be a good Docker build. For one thing, `edgyr` is 14 GB in size. For another, this is based on the old `Rocker` scripts. It does, however, serve the limited purpose of getting RStudio running with a native build on R on Apple M1 laptops.  PRs are welcome!  
