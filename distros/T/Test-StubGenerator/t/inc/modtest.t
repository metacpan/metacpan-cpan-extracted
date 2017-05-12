#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

BEGIN { use_ok( 'MyObj' ); }

ok( my $obj = MyObj->new(), 'can create object MyObj' );
isa_ok( $obj, 'MyObj', 'object $obj' );
can_ok( $obj, 'get_name', 'set_names' );

# Create some variables with which to test the MyObj objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
my @names = ( '', );

# And now to test the methods/subroutines.
ok( $obj->get_name(), 'can call $obj->get_name() without params' );

ok( $obj->set_names( @names ), 'can call $obj->set_names()' );
ok( $obj->set_names(), 'can call $obj->set_names() without params' );


