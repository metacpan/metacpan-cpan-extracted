#!perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw/catfile/;
use lib catfile($FindBin::Bin, '..', 'lib');

use Test::Synopsis::Expectation;

my $target_file = catfile($FindBin::Bin, 'sample.pod');
synopsis_ok($target_file);

done_testing;
