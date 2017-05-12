use strict;
use warnings;

use Test::More tests => 3;

# ---------------------------------------------

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my %existing_methods = do {
    no strict 'refs';
    map {
        $_ => undef
    } grep {
        /^[a-zA-Z_]+$/
    } grep {
        exists &{${ $CLASS . '::'}{$_}}
    } keys %{ $CLASS . '::'}
};

my %methods = (
    class => [ qw(
        connect create_datastore _instantiate
    )],
    public => [ qw(
    )],
    private => [ qw(
    )],
    book_keeping => [qw(
    )],
    imported => [qw(
        blessed refaddr
    )],
);

# These are the class methods
can_ok( $CLASS, @{ $methods{class} } );
delete @existing_methods{@{$methods{class}}};

if ( my @k = keys %existing_methods ) {
    ok( 0, "We need to account for '" . join ("','", @k) . "'" );
}
else {
    ok( 1, "We've accounted for everything." );
}
