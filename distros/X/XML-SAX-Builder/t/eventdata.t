# @(#) $Id: eventdata.t,v 1.1 2003/04/12 23:58:58 dom Exp $

# This test is mostly to check that we are outputting the correct
# information as SAX events.

use strict;
use warnings;

use Test::More tests => 6;

use Data::Dumper;
use XML::SAX::Builder;

{
    package Recorder;
    use vars '$AUTOLOAD';
    sub new { bless [], shift }
    sub AUTOLOAD {
        my $self = shift;
        my ( $class, $method ) = $AUTOLOAD =~ m/(.*)::(.*)/;
        push @$self, [ $method, @_ ];
    }
    sub reset{ @{$_[0]} = () }
    # Following XML::Filter::BufferText's example.
    sub characters;
    sub start_element;        sub end_element;
    sub start_document;       sub end_document;
    sub start_prefix_mapping; sub end_prefix_mapping;
    sub start_cdata;          sub end_cdata;
}

my $rec = Recorder->new;
my $x = XML::SAX::Builder->new( $rec );

my @tests = (

    {
        name     => 'simple xml',
        builder  => $x->foo( 'bar' ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_element', {
                'Prefix'       => '',
                'LocalName'    => 'foo',
                'Name'         => 'foo',
                'NamespaceURI' => '',
            } ],
            [ 'characters', { 'Data' => 'bar' } ],
            [ 'end_element', {
                'Prefix'       => '',
                'LocalName'    => 'foo',
                'Name'         => 'foo',
                'NamespaceURI' => '',
            } ],
            [ 'end_document', {} ],
        ],
    },

    #-----------------------------------------------------------------

    {
        name     => 'xml with default namespace',
        builder  => $x->xmlns( '' => 'urn:foo', $x->foo( 'bar' ) ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_prefix_mapping', {
                Prefix       => '',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'start_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => 'urn:foo',
                Attributes   => {
                    '{}xmlns' => {
                        Prefix       => '',
                        LocalName    => 'xmlns',
                        Value        => 'urn:foo',
                        Name         => 'xmlns',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'characters', { 'Data' => 'bar' } ],
            [ 'end_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => 'urn:foo',
                Attributes   => {
                    '{}xmlns' => {
                        Prefix       => '',
                        LocalName    => 'xmlns',
                        Value        => 'urn:foo',
                        Name         => 'xmlns',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'end_prefix_mapping', {
                Prefix       => '',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'end_document', {} ],
        ]
    },

    #-----------------------------------------------------------------

    {
        name     => 'xml with default namespace and attributes (which must be in empty ns)',
        builder  => $x->xmlns( '' => 'urn:foo', $x->foo( { id => 1 }, 'bar' ) ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_prefix_mapping', {
                Prefix       => '',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'start_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => 'urn:foo',
                Attributes   => {
                    '{}xmlns' => {
                        Prefix       => '',
                        LocalName    => 'xmlns',
                        Value        => 'urn:foo',
                        Name         => 'xmlns',
                        NamespaceURI => '',
                    },
                    '{}id' => {
                        Prefix       => '',
                        LocalName    => 'id',
                        Value        => '1',
                        Name         => 'id',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'characters', { 'Data' => 'bar' } ],
            [ 'end_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => 'urn:foo',
                Attributes   => {
                    '{}xmlns' => {
                        Prefix       => '',
                        LocalName    => 'xmlns',
                        Value        => 'urn:foo',
                        Name         => 'xmlns',
                        NamespaceURI => '',
                    },
                    '{}id' => {
                        Prefix       => '',
                        LocalName    => 'id',
                        Value        => '1',
                        Name         => 'id',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'end_prefix_mapping', {
                Prefix       => '',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'end_document', {} ],
        ]
    },

    #-----------------------------------------------------------------

    {
        name     => 'xml with nondefault namespace',
        builder  => $x->xmlns( 'foons' => 'urn:foo', $x->foo( 'bar' ) ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_prefix_mapping', {
                Prefix       => 'foons',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'start_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => '',
                Attributes   => {
                    '{http://www.w3.org/2000/xmlns/}xmlns:foons' => {
                        Prefix       => 'xmlns',
                        LocalName    => 'foons',
                        Value        => 'urn:foo',
                        Name         => 'xmlns:foons',
                        NamespaceURI => 'http://www.w3.org/2000/xmlns/',
                    }
                },
            } ],
            [ 'characters', { 'Data' => 'bar' } ],
            [ 'end_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => '',
                Attributes   => {
                    '{http://www.w3.org/2000/xmlns/}xmlns:foons' => {
                        Prefix => 'xmlns',
                        LocalName => 'foons',
                        Value => 'urn:foo',
                        Name => 'xmlns:foons',
                        NamespaceURI => 'http://www.w3.org/2000/xmlns/',
                    }
                },
            } ],
            [ 'end_prefix_mapping', {
                Prefix       => 'foons',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'end_document', {} ],
        ]
    },

    #-----------------------------------------------------------------

    {
        name     => 'xml with nondefault namespace and attributes (which must be in empty ns)',
        builder  => $x->xmlns( 'foons' => 'urn:foo', $x->foo( { id => 1 }, 'bar' ) ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_prefix_mapping', {
                Prefix       => 'foons',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'start_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => '',
                Attributes   => {
                    '{http://www.w3.org/2000/xmlns/}xmlns:foons' => {
                        Prefix       => 'xmlns',
                        LocalName    => 'foons',
                        Value        => 'urn:foo',
                        Name         => 'xmlns:foons',
                        NamespaceURI => 'http://www.w3.org/2000/xmlns/',
                    },
                    '{}id' => {
                        Prefix       => '',
                        LocalName    => 'id',
                        Value        => '1',
                        Name         => 'id',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'characters', { 'Data' => 'bar' } ],
            [ 'end_element', {
                Prefix       => '',
                LocalName    => 'foo',
                Name         => 'foo',
                NamespaceURI => '',
                Attributes   => {
                    '{http://www.w3.org/2000/xmlns/}xmlns:foons' => {
                        Prefix => 'xmlns',
                        LocalName => 'foons',
                        Value => 'urn:foo',
                        Name => 'xmlns:foons',
                        NamespaceURI => 'http://www.w3.org/2000/xmlns/',
                    },
                    '{}id' => {
                        Prefix       => '',
                        LocalName    => 'id',
                        Value        => '1',
                        Name         => 'id',
                        NamespaceURI => '',
                    }
                },
            } ],
            [ 'end_prefix_mapping', {
                Prefix       => 'foons',
                NamespaceURI => 'urn:foo',
            } ],
            [ 'end_document', {} ],
        ]
    },

    #-----------------------------------------------------------------

    {
        name     => 'xml with dodgy characters and cdata',
        builder  => $x->foo( $x->xmlcdata( '>bodgit&scarper<' ) ),
        expected => [
            [ 'start_document', {} ],
            [ 'start_element', {
                'Prefix'       => '',
                'LocalName'    => 'foo',
                'Name'         => 'foo',
                'NamespaceURI' => '',
            } ],
            [ 'start_cdata', {} ],
            [ 'characters', { 'Data' => '>bodgit&scarper<' } ],
            [ 'end_cdata', {} ],
            [ 'end_element', {
                'Prefix'       => '',
                'LocalName'    => 'foo',
                'Name'         => 'foo',
                'NamespaceURI' => '',
            } ],
            [ 'end_document', {} ],
        ],
    },

);

foreach my $t (@tests) {
    $x->xml( $t->{builder} );
    is_deeply( $rec, $t->{expected}, $t->{name} )
        or diag(Data::Dumper->Dump([$rec],['*got']));
    $rec->reset;
}

# vim: set ai et sw=4 syntax=perl :
