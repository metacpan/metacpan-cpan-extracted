#!perl -T
use strict;
use warnings;
use Test::More;


# public API
my $module    = "WWW::ColiPoste";
my @functions = ();
my @methods   = qw(new  get_status);


plan tests => 1 + 2*@functions + 2+2*@methods;

# load module
use_ok($module);

# check functions
for my $function (@functions) {
    can_ok($module, $function);
    can_ok(__PACKAGE__, $function);
}

# check methods
my $object = eval { $module->new };
is( $@, "", "creating a $module object" );
isa_ok( $object, $module, "check that the object" );

for my $method (@methods) {
    can_ok($module, $method);
    can_ok($object, $method);
}
