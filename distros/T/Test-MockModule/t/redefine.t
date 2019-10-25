use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule;

my $mocker = Test::MockModule->new('Mockee');

$mocker->redefine('good', 2);
is( Mockee::good(), 2, 'redefine() redefines the function' );

eval { $mocker->redefine('bad', 6) };
like( $@, qr/Mockee::bad/, 'exception when redefine()ing a nonexistent function' );

my $mocker2 = Test::MockModule->new('MockeeWithDestroy');

eval { $mocker2->redefine('what', 2) };

done_testing();

#----------------------------------------------------------------------

package Mockee;

our $VERSION;
BEGIN { $VERSION = 1 };

sub good { 1 }

#----------------------------------------------------------------------

package MockeeWithDestroy;

our $VERSION;
BEGIN { $VERSION = 1 };

sub DESTROY { print 'bad' if $_[0][1] };

1;
