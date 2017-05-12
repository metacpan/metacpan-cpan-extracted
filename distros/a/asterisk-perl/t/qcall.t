#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 5}

my $module_name = 'Asterisk::QCall';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw(queuedir queuetime create_qcall  );

can_ok( $module_name, @methods);

ok( $object->queuedir() eq "/var/spool/asterisk/qcall" , "Default queuedir value");
ok( $object->queuedir("/tmp/") eq "/tmp/", "Custom queuedir value");

