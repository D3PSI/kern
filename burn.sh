#!/bin/sh
make build-x86_64 && \
sudo dd if=dist/x86_64/kern.iso of=$1 status=progress
