use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $grok = catfile('bin', 'grok');

my $fork = qx/$^X $grok fork/;
my $kill = qx/$^X $grok kill/;

like($fork, qr/process/, "Got fork()");
like($kill, qr/TERM/, "Got kill()");
