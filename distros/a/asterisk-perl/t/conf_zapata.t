#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 4}

my $module_name = 'Asterisk::Conf::Zapata';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw(configfile channels readconfig writeconfig deletechannel setvariable helptext cgiform);

can_ok( $module_name, @methods);

$object->setvariable('channels' , '1-23','transfer', 'no');
my $expected = {  '1-23' => { 'transfer' => {'val' => 'no','precomment' => ";Modified by Asterisk::Config::Zapata\n"} } } ;
is_deeply( $object->{config}{channels} , $expected ,"setvariable datastructure");
