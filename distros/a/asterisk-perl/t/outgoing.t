#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 22}

my $module_name = 'Asterisk::Outgoing';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw(outdir outtime checkvariable setvariable create_outgoing);

can_ok( $module_name, @methods);

ok($object->outdir() eq "/var/spool/asterisk/outgoing", "Default outdir value");
ok($object->outdir("/var/outgoing") eq "/var/outgoing", "Custom outdir value");

my $time = time();
ok($object->outtime($time) eq $time , "Can set outtime");

my $variables = [ 'channel', 'maxretries', 'retrytime', 'waittime', 'context', 'extension', 'priority', 'application', 'data', 'callerid', 'setvar'];

for my $var ( @{$variables}) {
    ok( $object->checkvariable($var) == 1, "Checking allowed variable $var" )
}

my $not_allowed_var = "dummy";
ok( $object->checkvariable($not_allowed_var) == 0, "Checking unallowed variable");

my @set_vars = ( ["channel" , "6"] , [ "maxretries" , "2"], ["retrytime", "2"], ["waittime" , "2"]  );

# Allowed var set testing
for my $var (@set_vars){
    $object->setvariable( $var->[0] , $var->[1]);
    ok($object->{'OUTVARS'}{$var->[0]} == $var->[1] , "Allowed var $var->[0] set with value $var->[1]" );
}

# Custom var set testing
