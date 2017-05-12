use strict;
use warnings;
use Voldemort::Store;
use Voldemort::ProtoBuff::Connection;

my $connection = Voldemort::ProtoBuff::Connection->new(
    'to' => 'localhost:6666',
    'get_handler' =>
      Voldemort::ProtoBuff::GetMessage->new( { 'resolver' => Foo->new() } )
);

my $store = Voldemort::Store->new( connection => $connection );

$store->default_store('test');

#let's kill off any possibilities out there, a proper purge would do a get->... and delete each branch
my ( $value, $nodes ) = $store->get( { 'key' => 'pizza' } );
foreach my $node (@$nodes) {
    $store->delete( { 'key' => 'pizza', 'node' => $node } );
}

( $value, $nodes ) = $store->get( { 'key' => 'pizza' } );
print "Ensuring nothing exists: (" . (defined $value) . ")\n";

$store->put( { 'key' => 'pizza', 'value' => 'ham,pineapple', 'node' => 1 } );
$store->put( { 'key' => 'pizza', 'value' => 'pineapple',     'node' => 2 } );
$store->put( { 'key' => 'pizza', 'value' => 'pepers',        'node' => 3 } );

my $storedPizza;
( $storedPizza, $nodes ) = $store->get( { 'key' => 'pizza' } );
print "Using $storedPizza from the " . @$nodes . " versions\n";

# if we aren't in agreement, make ourselves agree!
foreach my $node (@$nodes) {
    foreach my $sub_node (@$node) {
        $store->put(
            { 'key' => 'pizza', 'value' => $storedPizza, 'node' => $sub_node }
        );
    }
}

( $storedPizza, $nodes ) = $store->get( { 'key' => 'pizza' } );
print "Using $storedPizza from the " . @$nodes . " versions\n";

package Foo;

use Moose;
use Voldemort::ProtoBuff::Resolver;
use Carp;

with 'Voldemort::Protobuff::Resolver';

sub resolve {
    shift;
    my $versions = shift;
    my $size = ( defined $versions ) ? scalar @{$versions} : 0;
    if ( $size == 0 ) {
        return ( undef, [] );
    }
    elsif ( $size == 1 ) {
        return $$versions[0]->value, [];
    }

    # pool everyone's likes
    my %result      = ();
    my %nodes       = ();
    my @nodeRecords = ();
    foreach my $record ( @{$versions} ) {
        map { $result{$_} = $_ } split( /,/, $record->value );
        map { $nodes{ $_->node_id } = 1 } @{ $record->version->entries };
        push @nodeRecords,
          [ map { $_->node_id } @{ $record->version->entries } ];
    }

    # filter out dislikes
    # people in group 1 needs two toppings
    # assume people in node 2 can't eat pork
    # fish is ok though by everyone but node 4, who are vegetarians

    my %removals = ();
    my $whiner   = 0;
    foreach my $key ( keys %nodes ) {
        if ( $key == 2 ) {
            map { $removals{$_} = $_ if defined $_ }
              delete @result{qw(ham pepperoni salami')};
        }
        if ( $key == 4 ) {
            map { $removals{$_} = $_ if defined $_ }
              delete @result{qw(chicken)};
        }
        elsif ( $key == 1 ) {
            $whiner = 1;
        }

    }

    # give way to the whiner!
    if ( $whiner and ( scalar keys %result ) < 2 ) {
        my @removals = keys %removals;
        $result{ pop @removals } = 1;
    }
    return ( join ",", keys %result ), \@nodeRecords;
}

1;
