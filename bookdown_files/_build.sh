#!/bin/sh

Rscript -e "bookdown::render_book('bookdown_files/index.Rmd', 'bookdown::gitbook')"
