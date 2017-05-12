package WebService::Lucene::XOXOParser;

use strict;
use warnings;

use XML::LibXML;

BEGIN {
    for my $name ( qw( dl dd dt ) ) {
        no strict 'refs';
        *$name = sub { _make_element( $name, @_ ) }
    }
}

my %pattern_lut = (
    '&' => 'amp',
    '<' => 'lt',
    '>' => 'gt',
    '"' => 'quot',
    "'" => 'apos',
);
my $pattern = join( '|', keys %pattern_lut );

=head1 NAME

WebService::Lucene::XOXOParser - Simple XOXO Parser

=head1 SYNOPSIS

    use WebService::Lucene::XOXOParser;
    
    my $parser     = WebService::Lucene::XOXOParser->new;
    my @properties = $parser->parse( $xml );

=head1 DESCRIPTION

This module provides simple XOXO parsing for Lucene documents.

=head1 METHODS

=head2 new( )

Creates a new parser instance.

=cut

sub new {
    my ( $class ) = @_;
    return bless {}, $class;
}

=head2 parse( $xml )

Parses XML and returns an array of hashrefs decribing each
property.

=cut

sub parse {
    my ( $self, $xml ) = @_;

    my $parser = XML::LibXML->new;
    my $root   = $parser->parse_string( $xml )->documentElement;
    my @nodes  = $root->findnodes( '//dt | //dd' );

    my @properties;
    while ( @nodes ) {
        my ( $term, $value ) = ( shift( @nodes ), shift( @nodes ) );

        my $property = {
            name  => $term->textContent,
            value => $value->textContent,
            map { $_->name => $_->value } $term->attributes
        };

        push @properties, $property;
    }

    return @properties;
}

=head2 construct( @properties )

Takes an array of properties and constructs
an XOXO XML structure.

=cut

sub construct {
    my ( $self, @properties ) = @_;

    return dl(
        { class => 'xoxo' },
        map {
            my $node = $_;
            dt( {   map { $_ => $node->{ $_ } }
                        grep { $_ !~ /^(name|value)$/ } keys %$_
                },
                $self->encode_entities( $_->{ name } )
                ),
                dd( $self->encode_entities( $_->{ value } ) )
            } @properties
    );
}

sub _make_element {
    my $element = shift;
    my $output  = "<$element";
    if ( ref $_[ 0 ] ) {
        my $attrs = shift;
        $output .= ' ';
        $output .= join( ' ',
            map { qq($_=") . $attrs->{ $_ } . '"' } keys %$attrs );
    }
    $output .= join( '', '>', @_, "</$element>" );
    return $output;
}

=head2 encode_entities( $value )

Escapes some chars to their entities.

=cut

sub encode_entities {
    my $self  = shift;
    my $value = shift;
    $value =~ s/($pattern)/&$pattern_lut{$1};/gso;

    return $value;
}

=head2 dl

Shortcut to create a definition list

=head2 dt

Shortcut to create a definition term

=head2 dd

Shortcut to create a definition description

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>brian.cassidy@nald.caE<gt>

=item * Adam Paynter E<lt>adam.paynter@nald.caE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
