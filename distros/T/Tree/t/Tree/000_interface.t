use strict;
use warnings;

use Test::More tests => 7;

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test plan:
# 1) Verify that the API is correct. This will serve as documentation for which methods
#    should be part of which kind of API.
# 2) Verify that all methods in $CLASS have been classified appropriately

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
        new error_handler QUIET WARN DIE
        PRE_ORDER POST_ORDER LEVEL_ORDER
    )],
    public => [ qw(
        is_root is_leaf
        add_child remove_child has_child get_index_for
        root parent children
        height width depth size
        error_handler error last_error
        value set_value
        clone mirror traverse
        add_event_handler event
		tree2string node2string format_node hashref2string
        meta
    )],
    private => [ qw(
        _null _fix_width _fix_height _fix_depth _init _set_root _strip_options
    )],
#    book_keeping => [qw(
#    )],
    imported => [qw(
        blessed refaddr weaken
    )],
);

# These are the class methods
can_ok( $CLASS, @{ $methods{class} } );
delete @existing_methods{@{$methods{class}}};

my $tree = $CLASS->new();
isa_ok( $tree, $CLASS );

for my $type ( qw( public private imported ) ) {
    can_ok( $tree, @{ $methods{ $type } } );
    delete @existing_methods{@{$methods{ $type }}};
}

if ( my @k = keys %existing_methods ) {
    ok( 0, "We need to account for '" . join ("','", @k) . "'" );
}
else {
    ok( 1, "We've accounted for everything." );
}
