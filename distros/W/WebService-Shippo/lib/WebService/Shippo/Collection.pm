use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Collection;
use Params::Callbacks ( 'callbacks' );
use base              ( 'WebService::Shippo::Resource' );

sub count
{
    my ( $invocant ) = @_;
    return $invocant->{count} 
        if ref $invocant;
    return $invocant->all( results => 1 )->{count};
}

sub page_size
{
    my ( $invocant ) = @_;
    return scalar( @{ $invocant->{results} } );
}

sub next_page
{
    my ( $callbacks, $invocant ) = &callbacks;
    return unless defined $invocant->{next};
    my $response = WebService::Shippo::Request->get( $invocant->{next} );
    return $invocant->item_class->construct_from( $response, $callbacks );
}

sub plus_next_pages
{
    my ( $callbacks, $invocant ) = &callbacks;
    return $invocant unless defined $invocant->{next};
    my $current = $invocant;
    while ( defined( $current->{next} ) ) {
        my $r = WebService::Shippo::Request->get( $current->{next} );
        $current = $invocant->item_class->construct_from( $r, $callbacks );
        push @{ $invocant->{results} }, @{ $current->{results} };
    }
    undef $invocant->{next};
    return $invocant;
}

sub previous_page
{
    my ( $callbacks, $invocant ) = &callbacks;
    return unless defined $invocant->{previous};
    my $response = WebService::Shippo::Request->get( $invocant->{previous} );
    return $invocant->item_class->construct_from( $response, $callbacks );
}

sub plus_previous_pages
{
    my ( $callbacks, $invocant ) = &callbacks;
    return $invocant unless defined $invocant->{previous};
    my $current = $invocant;
    while ( defined( $current->{previous} ) ) {
        my $r = WebService::Shippo::Request->get( $current->{previous} );
        $current = $invocant->item_class->construct_from( $r, $callbacks );
        unshift @{ $invocant->{results} }, @{ $current->{results} };
    }
    undef $invocant->{previous};
    return $invocant;
}

sub items
{
    my ( $callbacks, $invocant ) = &callbacks;
    return $callbacks->transform( @{ $invocant->{results} } )
        if wantarray;
    return [ $callbacks->transform( @{ $invocant->{results} } ) ];
}

sub item
{
    my ( $callbacks, $invocant, $position ) = &callbacks;
    return
        unless $position > 0 && $position <= $invocant->{count};
    return $callbacks->smart_transform( $invocant->{results}[ $position - 1 ] );
}

sub item_at_index
{
    my ( $callbacks, $invocant, $index ) = &callbacks;
    return $callbacks->smart_transform( $invocant->{results}[$index] );
}

BEGIN {
    no warnings 'once';
    *Shippo::Collection:: = *WebService::Shippo::Collection::;
    *to_array = *items;
}

1;
