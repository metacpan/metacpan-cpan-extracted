use strict;
use warnings;
use Test::More tests => 1;
use Test::ttserver;

my $ttserver1 = Test::ttserver->new
    or die $Test::ttserver::errstr;

my $ttserver2 = Test::ttserver->new
    or die $Test::ttserver::errstr;

isnt($ttserver1->port, $ttserver2->port, 'different port');
