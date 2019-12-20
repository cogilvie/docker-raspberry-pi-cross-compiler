#!/bin/bash

: ${RPXC_IMAGE:=cogilvie/raspberry-pi-cross-compiler}

docker build -t $RPXC_IMAGE .
