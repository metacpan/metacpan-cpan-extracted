use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('bin', 'grok');
my $result_short = qx/$^X $script -V/;
my $result_long = qx/$^X $script --version/;

like($result_short, qr/^grok (?:dev-git|\d)/, "Got version info (-V)");
like($result_long, qr/^grok (?:dev-git|\d)/, "Got version info (--version)");

