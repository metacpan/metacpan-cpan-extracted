use warnings;
use strict;

use Test::More;
use Test::Warnings;

package Mockee; ## no critic (Modules::RequireFilenameMatchesPackage)

sub good ($$); ## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub good ($$) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my ( $bar, $baz ) = @_;
    return ( $bar + 1, $baz + 2 );
}

1;

package main;

use Test::MockModule;

$INC{'Mockee.pm'} = 1;
my $mocker = Test::MockModule->new('Mockee');

# Verify original behavior
my @orig = Mockee::good(10, 20);
is_deeply(\@orig, [11, 22], 'original prototyped sub works');

# Redefine with a scalar value (no warnings expected for prototype mismatch)
$mocker->redefine( 'good', 42 );
is(Mockee::good(1, 2), 42, 'prototyped sub can be redefined with scalar');

# Redefine with a coderef
$mocker->redefine( 'good', sub { return $_[0] * $_[1] } );
is(Mockee::good(3, 7), 21, 'prototyped sub can be redefined with coderef');

# Unmock restores original
$mocker->unmock('good');
@orig = Mockee::good(10, 20);
is_deeply(\@orig, [11, 22], 'unmock restores original prototyped sub');

done_testing();
