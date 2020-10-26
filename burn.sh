#!/bin/sh
make && \
sudo dd if=kern.iso of=$1 status=progress 
