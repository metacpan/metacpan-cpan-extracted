use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('bin', 'grok');
my $locate_short = qx/$^X $script -l s02/;
my $locate_long  = qx/$^X $script --locate s02/;

like($locate_short, qr/S02-bits\.pod$/m, 'Found location of Synopsis 2 (-l)');
like($locate_long,  qr/S02-bits\.pod$/m, 'Found location of Synopsis 2 (--locate)');
