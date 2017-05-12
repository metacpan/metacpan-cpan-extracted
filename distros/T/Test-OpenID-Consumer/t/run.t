use warnings;
use strict;
use Test::More qw/no_plan/;
use_ok('Test::OpenID::Consumer');
my $s = Test::OpenID::Consumer->new;
my $url_root = $s->started_ok;

diag "root is $url_root";
