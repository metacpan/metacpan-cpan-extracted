use warnings;
use strict;
use Test::More qw/no_plan/;
use_ok('Test::OpenID::Server');
my $s = Test::OpenID::Server->new;
my $url_root = $s->started_ok("start up my web server");

