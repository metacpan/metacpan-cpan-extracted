#!/usr/bin/env bash
cat MANIFEST \
    | grep ^lib \
    | grep '\.pm$' \
    | grep -v 'lib/above.pm' \
    | grep -v 'lib/UR.pm' \
    | grep -v 'lib/UR/All.pm' \
    | perl -ne 'chomp; s|^lib/||; s|\.pm$||; s|/|::|g; print "use $_;\n";'
