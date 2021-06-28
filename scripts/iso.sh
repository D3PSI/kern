#!/usr/bin/env bash

BOOT_DIR=$1
ISO_DIR=$2
KERN_ELF=$3
OUTPUT_FILE=$4


exit_missing() {
    printf "$_ must be installed\n";
    exit 1;
}

which xorriso > /dev/null || exit_missing
which grub-mkrescue > /dev/null || exit_missing
which readelf > /dev/null || exit_missing

mkdir -p $BOOT_DIR

cp -r grub $BOOT_DIR
cp $KERN_ELF $BOOT_DIR/"kern.elf"

grub-mkrescue -o $OUTPUT_FILE $ISO_DIR
