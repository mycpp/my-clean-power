#!/bin/sh
Rscript -e "devtools::install_github('rstudio/bookdown')"
Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
