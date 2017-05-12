#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 5}

my $module_name = 'Asterisk::Zapata';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw(configfile setvar channels readconfig  );

can_ok( $module_name, @methods);

ok( $object->configfile() eq '/etc/asterisk/zapata.conf' , "Default zapata conf file" ) ;
ok( $object->configfile('/tmp/etc/asterisk/zapata.conf') eq '/tmp/etc/asterisk/zapata.conf' , "Custom zapata conf file" ) ;

