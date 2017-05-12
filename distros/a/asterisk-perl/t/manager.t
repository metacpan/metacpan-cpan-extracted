#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 3}

my $module_name = 'Asterisk::Manager';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw( user secret host port connected error debug connfd
read_response connect astman_h2s astman_s2h sendcommand setcallback eventcallback
eventloop handleevent action command disconnect  splitresult );

can_ok( $module_name, @methods);