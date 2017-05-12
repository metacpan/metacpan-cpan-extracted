use strict;
use warnings;
use Test::Fixme;
use File::Spec;

run_tests(
  manifest => File::Spec->catfile(qw( t dirs manifest MANIFEST ))
);
