#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 4;

use lib (File::Spec->catdir($Bin, 'lib'));

my $DIRECT = <<DIRECT;
use true;
0;
DIRECT

my $INDIRECT = <<INDIRECT;
use Contemporary::Perl::Subclass::Subclass;
0;
INDIRECT

is eval($DIRECT), 0, "direct: true doesn't affect non-require evals";
ok not($@), 'direct: no eval error';
is eval($INDIRECT), 0, "indirect: true doesn't affect non-require evals";
ok not($@), 'indirect: no eval error';
