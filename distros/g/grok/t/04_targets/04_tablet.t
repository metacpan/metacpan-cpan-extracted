use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $grok = catfile('bin', 'grok');

my $fork = qx/$^X $grok chdir/;
my $kill = qx/$^X $grok chop/;

like($fork, qr/directory/, "Got chdir()");
like($kill, qr/string/, "Got chop()");
