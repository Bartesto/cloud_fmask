################################################################################
# fmaskR is a wrapper function for using the Python command line scripts to 
# produce cloud masks for USGS Landsat scenes utilising the fmask algorithms.
#
# Prerequisites:
# For this function to run Python and fmask and dependent modules must be 
# installed first. See fmaskR html doco for details.
#
# params
# imdir -  location to USGS Landsat imagery at the path/row level
# Aenv -   environment name assigned within Anaconda Prompt that has been set up 
#          to pre-load all the relevent Python modules. Set as default setup. 
#          See fmaskR html doco for details.
# pyPath - path to fmask_expandWildcards.py script. See fmaskR html doco for
#          details.
#
# Bart Huntley 05/08/16


fmaskR <- function(imdir, Aenv = "myenv", pyPath){
  start <- Sys.time()
  setwd(imdir)
  
  ## Helper functions
  list.dirs <- function(path=".", pattern=NULL, all.dirs=FALSE,
                        full.names=FALSE, ignore.case=FALSE) {
    # use full.names=TRUE to pass to file.info
    all <- list.files(path, pattern, all.dirs,
                      full.names=TRUE, recursive=FALSE, ignore.case)
    dirs <- all[file.info(all)$isdir]
    # determine whether to return full names or just dir names
    if(isTRUE(full.names))
      return(dirs)
    else
      return(basename(dirs))
  }
  
  ## Sensor specific arguments
  ref5 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o ref.img", 
                "L*_B[1,2,3,4,5,7].TIF")
  thermal5 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o",
                    "thermal.img L*_B6.TIF")
  
  ref7 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o", 
                "ref.img L*_B[1,2,3,4,5,7].TIF")
  thermal7 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o", 
                    "thermal.img L*_B6_VCID_?.TIF")
  
  ref8 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o", 
                "ref.img LC8*_B[1-7,9].TIF")
  thermal8 <- paste("gdal_merge.py -separate -of HFA -co COMPRESSED=YES -o", 
                    "thermal.img LC8*_B1[0,1].TIF")
  
  ## Generic arguments
  envArg <- paste("activate", Aenv, "&")
  pyArg <- paste("python", pyPath)
  anglesArg <- paste("fmask_usgsLandsatMakeAnglesImage.py -m *_MTL.txt -t", 
                     "ref.img -o angles.img")
  saturationArg <- paste("fmask_usgsLandsatSaturationMask.py -i", 
                         "ref.img -m *_MTL.txt -o saturationmask.img")
  toaArg <- paste("fmask_usgsLandsatTOA.py -i ref.img -m *_MTL.txt -z", 
                  "angles.img -o toa.img")
  cloudArg <- paste("fmask_usgsLandsatStacked.py -t thermal.img -a", 
                    "toa.img -m *_MTL.txt -z angles.img -s saturationmask.img",
                    "-o cloud.img") 
  
  ## create cloud masks using fmask
  folders <- list.dirs()
  for(i in 1:length(folders)){
    setwd(paste0(imdir, "\\", folders[i]))
    
    ## message
    print(paste("Working in folder", folders[i]))
    
    ## check for existence of old MTL txt files and remove
    mtl <- list.files(pattern = "MTL.txt")
    if(length(mtl) > 0){file.remove(mtl)}
    
    ## check for existence of cloud mask
    cmask <- list.files(pattern = "cloud.img")
    if(length(cmask) == 0){
      
      ## for name of cloud mask output
      usgsname <- paste0(substr(list.files(pattern = ".pre.ers"), 1 , 9),
                         substr(list.files(pattern = ".pre.ers"), 11 , 16))
      
      ## determine if file unzipped if no unzip it
      zipped <- list.files(pattern = ".tar.gz")
      files <- list.files(pattern = ".TIF")
      if(length(files) == 0){untar(zipped)}
      
      ## get sensor for specific arguments
      sensor <- substr(zipped, 3,3)
      
      ## setup .img arguments
      # ref.img
      if (sensor == "5") {
        refimg <- paste(envArg, pyArg, ref5)  
      } else if (sensor == "7") {
        refimg <- paste(envArg, pyArg, ref7)
      } else
        refimg <- paste(envArg, pyArg, ref8)
      # thermal.img
      if (sensor == "5") {
        thermalimg <- paste(envArg, pyArg, thermal5) 
      } else if (sensor == "7") {
        thermalimg <- paste(envArg, pyArg, thermal7) 
      } else
        thermalimg <- paste(envArg, pyArg, thermal8)
      # angles.img
      anglesimg <- paste(envArg, pyArg, anglesArg)
      # saturationmask.img
      satimg <- paste(envArg, pyArg, saturationArg)
      # toa.img
      toaimg <- paste(envArg, pyArg, toaArg)
      # cloud.img
      cloudimg <- paste(envArg, pyArg, cloudArg)
      # all .img arguments in a list
      imgList <- list(refimg, thermalimg, anglesimg, satimg, toaimg, cloudimg)
      
      ## process using fmask python calls through shell
      for(k in 1:length(imgList)){
        shell(imgList[k])
      }
      
      ## clean up unzipped files
      notneeded <- list.files(pattern = ".TIF|GCP.txt") 
      file.remove(notneeded)
      
      ## clean up other img rasters - adjust if you want to keep
      xtraimg <- list.files(pattern = "angles|saturationmask|toa|thermal|ref")
      file.remove(xtraimg)
      
      ## rename .img files
      imgs <- list.files(pattern = ".img")
      newimgs <- paste(usgsname, imgs, sep = "_")
      file.rename(imgs, newimgs)
      
      ## message
      print(paste("Finished with folder", folders[i]))
      
    }
    
  }
  
  ## time stats
  end <- Sys.time()
  tot <- end - start
  
  ## completion message
  setwd(imdir)
  completedmasks <- list.files(pattern = "cloud.img", recursive = TRUE)
  
  print(paste("I have made", length(completedmasks)/2, 
              "cloud masks and it took me", round(tot, 2), "hours"))
}

imdir <- "C:\\temp\\R_development\\fmask"
Aenv = "myenv"
pyPath = paste0("C:\\Users\\barth\\AppData\\Local\\Continuum\\Miniconda2\\envs",
                "\\myenv\\Scripts\\fmask_expandWildcards.py")

fmaskR(imdir, Aenv, pyPath)