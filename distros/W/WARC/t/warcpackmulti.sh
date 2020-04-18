#!/bin/sh

# Pack compression variants of a WARC file

dir=`dirname $0`;

stem=${1%.warc}

# Variants differ in presence, absence, and validity of the "sl" gzip
# extension header.

set -xe

${dir}/warcpack.pl ${stem}.warc -o ${stem}.warc.gz
${dir}/warcpack.pl ${stem}.warc -o ${stem}.xh.warc.gz --extra-header
${dir}/warcpack.pl ${stem}.warc -o ${stem}.vsl.warc.gz --with-sl=valid
${dir}/warcpack.pl ${stem}.warc -o ${stem}.esl.warc.gz --with-sl=empty
${dir}/warcpack.pl ${stem}.warc -o ${stem}.b1sl.warc.gz --with-sl=bogus1
${dir}/warcpack.pl ${stem}.warc -o ${stem}.b2sl.warc.gz --with-sl=bogus2
${dir}/warcpack.pl ${stem}.warc -o ${stem}.b3sl.warc.gz --with-sl=bogus3
${dir}/warcpack.pl ${stem}.warc -o ${stem}.b4sl.warc.gz --with-sl=bogus4
