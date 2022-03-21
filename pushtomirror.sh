#!/bin/bash

rsync -av --delete _dist/ repo.aosc.io:/mirror/misc/neruthes/githubdistweb/miscdoc/
