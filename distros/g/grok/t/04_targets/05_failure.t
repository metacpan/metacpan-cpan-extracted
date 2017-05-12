use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 1;

# grok should die with an error message if the target is not recognized
my $grok = catfile('bin', 'grok');

my $target = 'definitely_completely_unrecognized_target';
my $result = qx/$^X $grok $target 2>&1/;
like($result, qr/^Target '$target' not recognized$/, "Sane error message");
