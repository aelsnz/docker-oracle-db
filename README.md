# Description

This repository contains a number of example to create oracle 10g to 19c docker images for testing etc.
The base images to create is the oracle linux 5, 6 and 7 images with updates and few extra pre-requisites
Then you can build the other images.

# Requirements

To install Oracle software using these docker build steps you will need to download the required versions 
and place them in the relevant software sub folder.  
You will require an Oracle account and license/support agreement to add patches.  Some of the builds include a few
patches which you can download, or you can just remove those steps from the build (Dockerfile).

1. Build the Oracle Linux images first.  
  *  These images are located in the "oel" subfolder.  Some of these steps could be added to the other docker images, but I sometimes use Oracle Linux for other things as well and then these images come in handy.  They do include a number of extra software packages that in most cases should meet the database requirements, but also include a few nice to have options like "jq".  

2.  Pick the database version you want to build, download the software and place it in software sub folder and then run the "build.sh" script.  There is a README.md file in each sub folder with more detail and I will add more detail there over time.

  *  A note on the build.sh script - you will notice that it does an export/import after the base build of the image, this is to squash the layers as these images can take up a lot of space.  Remember when you install the Oracle software it will take at least that much space.
  *  These images and scripts provided should be easy to customize to your needs


# Options
You can either install the Oracle software and create a database at the same time and store it in the image, which 
can be useful for testing, but the key here is the images will be big and there is no persistence.  The other option
is to create the images with the Oracle database software installed, then once that is done, you can use the image
to create new containers and create the databases on persistant volumes.

# Work in Progress
Please note that this repository is a work in progress, there is still a lot that can be added, updated and optimized, but sharing this as others might find it useful or might help get you started with docker.

If you are interested in Oracle Express 18c - please see https://github.com/aelsnz/docker-xe


