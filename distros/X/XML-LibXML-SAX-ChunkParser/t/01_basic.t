package XLSC_Test;
use strict;
our $AUTOLOAD;
use Data::Dumper;
use Test::More;

my @EVENTS = (
    {
        Event => 'start_document'
    },
    {
        Event => 'xml_decl',
        Version => '1.0'
    },
    {
        Event => 'start_prefix_mapping',
        Prefix => '',
        NamespaceURI => 'http://foobar.com',
    },
    {
        Event => 'start_element',
        LocalName => 'foo',
        Prefix => '',
        Attributes => {
            '{}xmlns' => {
                LocalName => 'xmlns',
                Prefix => '',
                Value => 'http://foobar.com',
                Name => 'xmlns',
                NamespaceURI => '',
            }
        },
        Name => 'foo',
        NamespaceURI => 'http://foobar.com',
    },
    {
        Event => 'start_element',
        LocalName => 'bar',
        Prefix => '',
        Attributes => {
            '{}x' => {
                LocalName => 'x',
                Prefix => '',
                Value => 1,
                Name => 'x',
                NamespaceURI => ''
            }
        },
        Name => 'bar',
        NamespaceURI => 'http://foobar.com'
    },
    {
        Event => 'start_element',
        LocalName => 'baz',
        Prefix => '',
        Attributes => {},
        Name => 'baz',
        NamespaceURI => "http://foobar.com"
    },
    {
        Event => 'characters',
        Data => 'whoopla',
    },
    {
        Event => 'end_element',
        LocalName => 'baz',
        Prefix => '',
        Name => 'baz',
        NamespaceURI => 'http://foobar.com'
    },
    {
        Event => 'end_element',
        LocalName => 'bar',
        Prefix => '',
        Name => 'bar',
        NamespaceURI => 'http://foobar.com'
    },
    {
        Event => 'end_element',
        LocalName => 'foo',
        Prefix => '',
        Name => 'foo',
        NamespaceURI => 'http://foobar.com'
    },
    {
        Event => 'end_prefix_mapping',
        Prefix => '',
        NamespaceURI => 'http://foobar.com',
    }
);

sub new { bless { events => [ @EVENTS ] }, shift }

sub DESTROY { }
sub AUTOLOAD {
    my ($self, $arg) = @_;

    my $got_event = $AUTOLOAD;
    $got_event =~ s/^.+:://;

    $arg ||= {};
    my $expected = shift @{ $self->{events} };
    my $event    = delete $expected->{Event};
    is ($got_event, $event, "event should be $event");
    is_deeply( $arg, $expected );
}


package main;
use strict;
use Test::More( tests => 23 );
use XML::SAX;

XML::SAX->add_parser( q{XML::LibXML::SAX::ChunkParser} );

{
    my $parser = XML::SAX::ParserFactory->parser( Handler => XLSC_Test->new );
    isa_ok($parser, "XML::LibXML::SAX::ChunkParser" );
}

{
    my @chunks = (
        q|<?xml v|,
        q|ersion="1.0"?>|,
        q|<foo xml|,
        q|ns="http://foobar.com">|,
        q|<|,
        q|bar x="1"|,
        q|>|,
        q|<baz>whoopla</b|,
        q|az>|,
        q|<|,
        q|/|,
        q|bar>|,
        q|</foo>|,
    );

    my $parser = XML::SAX::ParserFactory->parser( Handler => XLSC_Test->new );
    foreach my $chunk (@chunks) {
        diag("parsing chunk '$chunk'");
        $parser->parse_chunk($chunk);
    }
}