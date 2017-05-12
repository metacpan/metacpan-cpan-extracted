#!/bin/zsh

set -e

cd $0:h

if ! perl -I../../.. -MYATT::Lite -e0; then
    cat 1>&2 <<EOF; exit 1
$0: Can't find YATT::Lite, exiting...
EOF

fi

if ((ARGC)); then
    savename=$1; shift
else
    savename=$HOST
fi

for tst in yt-*; do
    echo "#========"
    echo "# $tst"
    echo "#========"
    ./$tst
    echo; echo
done | tee results/$savename.txt
