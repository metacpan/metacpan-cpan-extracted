#!/bin/bash
rm MANIFEST
perl Makefile.PL &&
    make && cover -test &&
    make manifest &&
    make tardist
