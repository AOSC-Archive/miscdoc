#!/bin/bash

rsync -av --delete _dist/ repo.aosc.io:/mirror/misc/artifacts/miscdoc/
ssh repo.aosc.io 'cd /mirror/misc/artifacts; tar vcf /mirror/misc/artifacts.tar/miscdoc.tar miscdoc'




#######################################################################




### Verify tarball content:
# cd /mirror/misc/artifacts.tar; ls; du -h miscdoc.tar; tar pxvf miscdoc.tar; tree;
# rm -rf /mirror/misc/artifacts.tar/miscdoc*
