# Usage
This sub folder can be used to create an Oracle 11gR2 - 11.2.0.4 docker image using oracle linux 7
You must download / have appropriate license to use the software/patches.
This is an example of how you can build these images 

Required files in software sub folder:

Oracle 11204 software
* p13390677_112040_Linux-x86-64_1of7.zip
* p13390677_112040_Linux-x86-64_2of7.zip

Pathces, if you do not have these, you can remove them from dockerfile to not be installed
* p6880880_112000_Linux-x86-64.zip
* p19121551_112040_Linux-x86-64.zip
* p23615392_112040_Linux-x86-64.zip

# Notes
Oracle Repsonse files are used - samples are provided in the scripts sub folder