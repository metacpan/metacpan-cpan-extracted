#!/usr/local/lib/perl -w

use strict;

#use Devel::TraceSAX;

use Carp;
use Test;
use XML::Filter::Dispatcher qw( :all );
use UNIVERSAL;

my $has_graph;

BEGIN { $has_graph = eval "require Graph;" ? 1 : 0 }

plan tests => 16 + $has_graph * 2 * 2;

{
    my $d = XML::Filter::Dispatcher->new(
        Rules => [
            "/" => sub {
                xpush "doc";
                ok xpeek, "doc";
                ok xpeek(0), "doc";
                ok xpeek(-1), "doc";
            },
            "//a" => sub {
                ok xpeek, "doc";

                xpush "a";
                ok xpeek,     "a";
                ok xpeek(-1), "a";
                ok xpeek(1),  "a";
                ok xpeek(0),  "doc";
            },
            "//b" => sub {
                ok xpeek, "a";

                xpush "b";
                ok xpeek,     "b";
                ok xpeek(-1), "b";
                ok xpeek(2),  "b";
                ok xpeek(1),  "a";
            },
            "//end-element::b" => sub {
                ok xpeek, "b";
            },
            "//end-element::a" => sub {
                ok xpeek, "a";
            },
            "/end-document::*" => sub {
                ok xpeek, "doc";
            },
        ],
    );

    QB->new( "ab", "<a><b/></a>" )->playback( $d );
}

{
    ## old style
    my $d = XML::Filter::Dispatcher->new(
        Rules => [
            graph  => sub { xpush( Graph->new() ); },

            vertex => sub {
                xpeek->add_vertex(
                    $_[1]->{Attributes}->{"{}name"}->{Value}
                );
            },

            edge => sub {
                xpeek->add_edge(
                    $_[1]->{Attributes}->{"{}from"}->{Value},
                    $_[1]->{Attributes}->{"{}to"  }->{Value},
                );
            },

            # The result of the last handler is returned.
            'end::graph' => \&xpop,
        ],
    );

    my $got = QB->new( "graph", <<END_XML )->playback( $d );
<graph>
    <vertex name="0" />
    <edge from="1" to="2" />
    <edge from="2" to="1" />
</graph>
END_XML

    my $expected = Graph->new->add_cycle( 1, 2 )->add_vertex( 0 );

    ok $got, $expected;
    ok $got->complete;
}

{
    ## new style
    my $d = XML::Filter::Dispatcher->new(
        Rules => [
            'graph'        => sub { xpush( Graph->new ) },
            'end::graph'   => \&xpop,
            'vertex'       => [ 'string( @name )' => sub { xadd     } ],
            'edge'         => [ 'string()'        => sub { xpush {} } ],
            'edge/@*'      => [ 'string()'        => sub { xset     } ],
            'end::edge'    => sub { 
                my $edge = xpop;
                xpeek->add_edge( @$edge{"from","to"} );
            },
        ],
    );

    my $got = QB->new( "graph", <<END_XML )->playback( $d );
<graph>
    <vertex name="0" />
    <edge from="1" to="2" />
    <edge from="2" to="1" />
</graph>
END_XML

    my $expected = Graph->new->add_cycle( 1, 2 )->add_vertex( 0 );

    ok $got, $expected;
    ok $got && $got->complete;
}

###############################################################################
##
## This quick little buffering filter is used to save us the overhead
## of a parse for each test.  This saves me sanity (since I run the test
## suite a lot), allows me to see which tests are noticably slower in
## case something pathalogical happens, and keeps admins from getting the
## impression that this is a slow package based on test suite speed.
package QB;
use vars qw( $AUTOLOAD );
use File::Basename;

sub new {
    my $self = bless [], shift;

    my ( $name, $doc ) = @_;

    my $cache_fn = basename( $0 ) . ".cache.$name";
    if ( -e $cache_fn && -M $cache_fn < -M $0 ) {
        my $old_self = do $cache_fn;
        return $old_self if defined $old_self;
        warn "$!$@";
        unlink $cache_fn;
    }

    require XML::SAX::PurePerl; ## Cannot use ParserFactory; LibXML 1.31 is broken.
    require Data::Dumper;
    my $p = XML::SAX::PurePerl->new( Handler => $self );
    $p->parse_string( $doc );
    if ( open F, ">$cache_fn" ) {
        local $Data::Dumper::Terse;
        $Data::Dumper::Terse = 1;
        print F Data::Dumper::Dumper( $self );
        close F;
    }

    return $self;
}

sub DESTROY;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*://;
    if ( $AUTOLOAD eq "start_element" ) {
        ## Older (and mebbe newer :) X::S::PurePerls reuse the same
        ## hash in end_element but delete the Attributes, so we need
        ## to copy.  And I can't copy everything because some other
        ## overly magical thing dies, haven't tracked down beyond seeing
        ## signs that it's XML::SAX::DocumentLocator::NEXTKEY(/usr/local/lib/perl5/site_perl/5.6.1/XML/SAX/DocumentLocator.pm:72)
        ## but I hear that's fixed in CVS :).
        push @$self, [ $AUTOLOAD, [ { %{$_[0]} } ] ];
    }
    else {
        push @$self, [ $AUTOLOAD, [ $_[0] ] ];
    }
}

sub playback {
    my $self = shift;
    my $h = shift;
    my $r;
    for ( @$self ) {
        my $m = $_->[0];
        no strict "refs";
        $r = $h->$m( @{$_->[1]} );
    }
    return $r;
}
