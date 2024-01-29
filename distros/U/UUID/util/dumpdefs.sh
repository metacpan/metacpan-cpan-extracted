#
# extract the #undef's from usrc/config.h.in
# and print to stdout.
#
# this can be piped to defsseen.pl too.
#
grep -P '^#\s*undef ' usrc/config.h.in | perl -ple's/^\#\s*undef\s+//' | sort | uniq
