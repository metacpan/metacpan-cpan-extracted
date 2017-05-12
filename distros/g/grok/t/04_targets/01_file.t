use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 1;

# grok should fall back to reading from a (Pod 6) file if it doesn't
# recognize the target
my $file = catfile('t_source', 'basic.pod');
my $grok = catfile('bin', 'grok');

my $result = qx/$^X $grok $file/;
like($result, qr/Baz/, "Got result");
