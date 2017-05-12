use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 3}

my $module_name = 'Asterisk::Astman';
use_ok($module_name) or exit;

my $object = $module_name->new();
isa_ok($object, $module_name);

my @methods = qw( port host user secret connect  authenticate execute
defaultevent setevent managerloop arrtostr configfile setvar readconfig);
can_ok($module_name, @methods)