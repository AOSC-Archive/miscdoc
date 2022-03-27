#!/bin/bash

rsync -av --delete _dist/ repo.aosc.io:/mirror/misc/artifacts/miscdoc/
ssh repo.aosc.io 'cd /mirror/misc/artifacts; tar vcf /mirror/misc/artifacts.tar/miscdoc.tar miscdoc'

# rsync -av --delete .cidep/ repo.aosc.io:/mirror/misc/cidep/miscdoc/
tar -cf miscdoc.cidep.tar .cidep
scp miscdoc.cidep.tar repo.aosc.io:/mirror/misc/cidep/miscdoc/miscdoc.cidep.tar



#######################################################################




### Verify tarball content:
# cd /mirror/misc/artifacts.tar; ls; du -h miscdoc.tar; tar pxvf miscdoc.tar; tree;
# rm -rf /mirror/misc/artifacts.tar/miscdoc*
