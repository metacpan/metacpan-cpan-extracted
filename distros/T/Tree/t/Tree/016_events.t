use lib 't/lib';
use strict;
use warnings;

use Test::More;

#use Tests qw( %runs );

plan tests => 8;

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $tree = $CLASS->new( 'root' );

my @stack;
is( $tree->add_event_handler({
    add_child => sub {
        my ($node, @args) = @_;
        push @stack, "Added @args to $node";
    },
    value => sub {
        my ($node, $old, $new) = @_;
        push @stack, "Value changed: $old -> $new from $node";
    },
}), $tree, "add_event_handler() chains and handles multiple entries" );


my $child = $CLASS->new;
$tree->add_child( $child );

is( $stack[0], "Added $child to $tree", "Event triggered handler" );

my $child2 = $CLASS->new;
$child->add_child( $child2 );
is( $stack[1], "Added $child2 to $child", "Events bubble upwards to the parent" );

$child->add_event_handler({
    remove_child => sub {
        my ($node, @args) = @_;
        push @stack, "Removed @args from $node";
    },
});

$child->remove_child( $child2 );

is( $stack[2], "Removed $child2 from $child", "remove_child event" );

$tree->remove_child( $child );
cmp_ok( @stack, '==', 3, "Events trigger on the actor, not the acted-upon" );

$tree->set_value( 'new value' );

is( $stack[3], "Value changed: root -> new value from $tree", "remove_child event" );

$tree->value();

cmp_ok( @stack, '==', 4, "The value event only triggers when it's set, not accessed" );
