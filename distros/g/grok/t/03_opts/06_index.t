use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 6;

my $script = catfile('bin', 'grok');
my $index_short = qx/$^X $script -i/;
my $index_long  = qx/$^X $script --index/;

like($index_short, qr/^S02/m,     'Found Synopsis 2 in index (-i)');
like($index_long,  qr/^S02/m,     'Found Synopsis 2 in index (--index)');
like($index_short, qr/^say\b/m,   'Found say() in index (-i)');
like($index_long,  qr/^say\b/m,   'Found say() in index (--index)');
like($index_short, qr/^sleep\b/m, 'Found sleep() in index (-i)');
like($index_long,  qr/^sleep\b/m, 'Found sleep() in index (--index)');
