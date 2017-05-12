#!/usr/bin/perl

# Test the user data handling of the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 14;
use cPanel::TaskQueue::Task;

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, userdata=>5 } );
};
like( $@, qr/Expected a hash ref/, q{new: User data not a hash ref} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, userdata=>{ bad_a=>[], bad_h=>{}, bad_c =>sub{}, bad_g=>\*STDIN, good=>5 } } );
};
my $err = $@;
like( $err, qr/Reference values not/, q{new: Reference values.} );
$err =~ /: (.*?) at/mg;
is( $1, 'bad_a bad_c bad_g bad_h', 'new: Bad keys correctly identified.' );

my $t1 = cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, userdata=>{ num=>5, str=>'this is it' } } );
isa_ok( $t1, 'cPanel::TaskQueue::Task' );

is( $t1->get_userdata( 'num' ), 5, 'new: Data num is correct.' );
is( $t1->get_userdata( 'str' ), 'this is it', 'new: Data str is correct.' );

ok( !$t1->get_userdata( 'missing' ), 'new: Missing values are returned as false.' );

eval {
    $t1->mutate( {id=>2, userdata=>5} );
};
like( $@, qr/Expected a hash ref/, q{mutate: User data not a hash ref} );

eval {
    $t1->mutate( {id=>2, userdata=>{ bad_a=>[], bad_h=>{}, bad_c =>sub{}, bad_g=>\*STDIN, good=>5 }} );
};
$err = $@;
like( $err, qr/Reference values not/, q{mutate: Reference values.} );
$err =~ /: (.*?) at/mg;
is( $1, 'bad_a bad_c bad_g bad_h', 'mutate: Bad keys correctly identified.' );

my $t2 = $t1->mutate( {id=>2, userdata=>{ num=>17, new=>'Newly added' }} );

is( $t2->get_userdata( 'num' ), 17, 'mutate: Data num is changed.' );
is( $t2->get_userdata( 'str' ), 'this is it', 'mutate: Data str is unchanged.' );
is( $t2->get_userdata( 'new' ), 'Newly added', 'mutate: New field added.' );

ok( !$t2->get_userdata( 'missing' ), 'mutate: Missing value is still missing.' );

