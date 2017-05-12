#!perl -T
# @(#) $Id: xml-filter-normalize.t 1023 2005-10-21 20:47:45Z dom $

use strict;
use warnings;

use Test::More tests => 19;
use XML::Filter::Normalize;
use XML::NamespaceSupport;

# Pull in a small utility module for the tests to use.
use lib 't';
use Recorder;

my $TEST_NS = 'http://example.com/ns/';

test_basics();

my @test_data = (
    {
        desc => 'preserves correct input',
        in => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Attributes   => {},
        },
        expected => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'preserves correct input in no namespace',
        in => {
            Prefix       => '',
            NamespaceURI => '',
            LocalName    => 'bar',
            Name         => 'bar',
            Attributes   => {},
        },
        expected => {
            Prefix       => '',
            NamespaceURI => '',
            LocalName    => 'bar',
            Name         => 'bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'preserves correct input in default namespace',
        in => {
            Prefix       => '',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'bar',
            Attributes   => {},
        },
        expected => {
            Prefix       => '',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Name',
        in => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Attributes   => {},
        },
        expected => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Prefix',
        in => {
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Attributes   => {},
        },
        expected => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing LocalName',
        in => {
            Prefix       => 'foo',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Attributes   => {},
        },
        expected => {
            Prefix       => 'foo',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing LocalName in default Namespace',
        in => {
            Prefix       => '',
            Name         => 'bar',
            NamespaceURI => $TEST_NS,
            Attributes   => {},
        },
        expected => {
            Prefix       => '',
            NamespaceURI => $TEST_NS,
            LocalName    => 'bar',
            Name         => 'bar',
            Attributes   => {},
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing NamespaceURI',
        ns => [ [ foo => $TEST_NS ] ],
        in => {
            Attributes   => {},
            LocalName    => 'bar',
            Name         => 'foo:bar',
            Prefix       => 'foo',
        },
        expected => {
            Attributes   => {},
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Prefix & Name',
        ns => [ [ foo => $TEST_NS ] ],
        in => {
            Attributes   => {},
            LocalName    => 'bar',
            NamespaceURI => $TEST_NS,
        },
        expected => {
            Attributes   => {},
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Prefix & NamespaceURI',
        ns => [ [ foo => $TEST_NS ] ],
        in => {
            Attributes   => {},
            Name         => 'foo:bar',
            LocalName    => 'bar',
        },
        expected => {
            Attributes   => {},
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Prefix in Attribute',
        ns   => [ [ foo => $TEST_NS ] ],
        in   => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    NamespaceURI => $TEST_NS,
                    Value        => 42,
                },
            },
            Name         => 'foo:bar',
            LocalName    => 'bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
        expected => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    NamespaceURI => $TEST_NS,
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing NamespaceURI in Attribute',
        ns   => [ [ foo => $TEST_NS ] ],
        in   => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            Name         => 'foo:bar',
            LocalName    => 'bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
        expected => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    NamespaceURI => $TEST_NS,
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects missing Name in Attribute',
        ns   => [ [ foo => $TEST_NS ] ],
        in   => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    NamespaceURI => $TEST_NS,
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            Name         => 'foo:bar',
            LocalName    => 'bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
        expected => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    NamespaceURI => $TEST_NS,
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
    #----------------------------------------
    {
        desc => 'corrects Attribute key errors',
        in   => {
            Attributes => {
                "{}baz" => {
                    LocalName    => 'baz',
                    NamespaceURI => $TEST_NS,
                    Name         => 'foo:bar',
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            Name         => 'foo:bar',
            LocalName    => 'bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
        expected => {
            Attributes => {
                "{$TEST_NS}baz" => {
                    LocalName    => 'baz',
                    Name         => 'foo:baz',
                    NamespaceURI => $TEST_NS,
                    Prefix       => 'foo',
                    Value        => 42,
                },
            },
            LocalName    => 'bar',
            Name         => 'foo:bar',
            NamespaceURI => $TEST_NS,
            Prefix       => 'foo',
        },
    },
);
test_correct_element_data( $_ ) foreach @test_data;

my @exceptions_data = (
    {
        desc => 'no input data at all',
        in => {},
        expected => 'No LocalName found',
    },
);
test_bad_element_data( $_ ) foreach @exceptions_data;

# Now that all looks ok, try some real SAX work.
test_sax_handler();

#------------------------------------------------------------

sub test_basics {
    my $norm = XML::Filter::Normalize->new();
    isa_ok( $norm, 'XML::Filter::Normalize' );
    can_ok( $norm, qw( correct_element_data ) );
}

sub test_correct_element_data {
    my ( $t ) = @_;
    my $norm = XML::Filter::Normalize->new();

    # Add in any supplied namespaces.
    my $nsup = XML::NamespaceSupport->new();
    if ( $t->{ ns } ) {
        $nsup->push_context();
        $nsup->declare_prefix( @$_ ) foreach @{ $t->{ ns } };
    }

    my $out = $norm->correct_element_data( $nsup, $t->{ in } );
    is_deeply( $out, $t->{ expected }, "correct_element() $t->{ desc }" );
}

sub test_bad_element_data {
    my ( $t ) = @_;
    my $norm = XML::Filter::Normalize->new();
    my $nsup = XML::NamespaceSupport->new();

    eval { $norm->correct_element_data( $nsup, $t->{ in } ) };
    isa_ok( $@, 'XML::SAX::Exception' );
    is( "$@", "$t->{expected}\n", "test_bad_element_data: $t->{desc}" );
}

sub test_sax_handler {

    my $record = Recorder->new();
    my $norm   = XML::Filter::Normalize->new( Handler => $record );

    # Simulate a SAX parse, but with known b0rkenness.
    $norm->start_document( {} );
    $norm->start_prefix_mapping(
        { Prefix => 'foo', NamespaceURI => $TEST_NS } );
    my $el = {
        Prefix     => 'foo',
        LocalName  => 'bar',
        Attributes => {},
    };
    $norm->start_element( $el );
    $norm->end_element( $el );
    $norm->end_prefix_mapping(
        { Prefix => 'foo', NamespaceURI => $TEST_NS } );
    $norm->end_document( {} );

    my @expected = (
        [ start_document => {} ],
        [
            start_prefix_mapping =>
                { Prefix => 'foo', NamespaceURI => $TEST_NS }
        ],
        [
            start_element => {
                Name         => 'foo:bar',
                LocalName    => 'bar',
                Prefix       => 'foo',
                NamespaceURI => $TEST_NS,
                Attributes   => {},
            }
        ],
        [
            end_element => {
                Name         => 'foo:bar',
                LocalName    => 'bar',
                Prefix       => 'foo',
                NamespaceURI => $TEST_NS,
                Attributes   => {},
            }
        ],
        [ end_prefix_mapping => { Prefix => 'foo', NamespaceURI => $TEST_NS } ],
        [ end_document       => {} ],
    );
    my @events = $record->get_events;
    is_deeply( \@events, \@expected, 'XFN works as a SAX handler' )
        or dumpvar( [ \@events ], ['*events'] );
}

sub dumpvar {
    require Data::Dumper;
    diag( Data::Dumper->new(@_)->Indent(1)->Sortkeys(1)->Dump );
}

# vim: set ai et sw=4 syntax=perl :
