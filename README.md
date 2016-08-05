# cloud_fmask
Processes using fmask written for Python

Step 1 documents how to install Python and the necessary Python modules for using fmask using Conda from an install of Miniconda.

Step 2 outlines how to use the Anaconda Prompt to process USGS downloaded (unzipped) files with fmask. It produces a 
range of raster products such as a cloud mask and top of atmosphere reflectance. This is all achieved through a command line
interface.

fmaskR is a wrapper R function utilising the Python fmask. It contains some necessary adjustments to handle DPaW sun-corrected processed
USGS downloads. It will iterate over all downloaded scenes located in a path/row folder. See separate Rmd doco for details.
