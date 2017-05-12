use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('bin', 'grok');
my $result_short = qx/$^X $script -h/;
my $result_long = qx/$^X $script --help/;

like($result_short, qr/Options:/, "Got help message (-h)");
like($result_long, qr/Options:/, "Got help message (--help)");

