use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule;

my $mocker = Test::MockModule->new('Mockee')->mock( good => 51 )
  ->redefine( to_redefine => sub { 42 } )->define( something => 1234 );

isa_ok $mocker, 'Test::MockModule';

is( Mockee::good(),        51,   'mock() works when chaining with new' );
is( Mockee::to_redefine(), 42,   'redefine() works when chaining with new' );
is( Mockee::something(),   1234, 'something() works when chaining with new' );

done_testing();

#----------------------------------------------------------------------

package Mockee;

our $VERSION;
BEGIN { $VERSION = 1 }

sub good        { 1 }
sub to_redefine { 1 }

1;
