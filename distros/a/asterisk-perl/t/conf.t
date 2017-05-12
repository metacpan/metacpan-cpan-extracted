#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 4}

my $module_name = 'Asterisk::Conf';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw( configfile readconfig writeconfig setvariable variablecheck
cgiform  htmlheader htmlfooter deletecontext helptext);

can_ok( $module_name, @methods);

ok($object->configfile('/tmp/dummy') eq '/tmp/dummy' , 'Able to set configfile');

