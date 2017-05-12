#!/usr/local/lib/perl -w

use strict;

use Carp;
use Test;
use XML::Filter::Dispatcher qw( xvalue );
use XML::Filter::Dispatcher::AsHashHandler;
use UNIVERSAL;

my $has_graph;

my $h;

my $ab = QB->new( "ab", <<'XML_END' );
<root a="A">
    <a aa1="AA1" aa2="AA2">
        <b>B1</b>
        <b>B2</b>
    </a>
</root>
XML_END

my @ab_tests = (
sub { $h->{a} =~ /^\s+B1\s+B2\s+$/ ? ok 1 : ok $h->{a}, qr/^\s+B1\s+B2\s+$/ },
sub { ok $h->{'@a'    }, "A"   },
sub { ok $h->{'a/@aa1'}, "AA1" },
sub { ok $h->{'a/@aa2'}, "AA2" },
sub { ok $h->{'a/b'   }, "B2"  },
);

my $ns = QB->new( "ns", <<'XML_END' );
<root
    xmlns="default-ns"
    xmlns:foo="foo-ns"
    a="A"
    foo:a="FOOA"
>
    <a aa1="AA1" foo:aa1="AA2">
        <b>B1</b>
        <foo:b>B2</foo:b>
    </a>
</root>
XML_END

my @ns_tests = (
sub { ok $h->{'@a'        }, "A"    },
sub { ok $h->{'@bar:a'    }, "FOOA" },
sub { ok $h->{'a/@aa1'    }, "AA1"  },
sub { ok $h->{'a/@bar:aa1'}, "AA2"  },
sub { ok $h->{'a/b'       }, "B1"   },
sub { ok $h->{'a/bar:b'   }, "B2"   },
);

my @tests = (
sub {
    $h = $ab->playback( XML::Filter::Dispatcher::AsHashHandler->new );
#use Data::Dumper; warn Dumper( $h );
    ok ref $h, "HASH";
},
@ab_tests,
sub {
    $h = $ab->playback( 
        XML::Filter::Dispatcher->new(
            Rules => [
                "hash( root )" => \&xvalue,
            ],
#            Debug => 1,
        )
    );
#use Data::Dumper; warn Dumper( $h );
    ok ref $h, "HASH";
},
@ab_tests,

sub { ok $h->{a} =~ /^\s+B1\s+B2\s+$/ },

sub {
    $h = $ns->playback(
        XML::Filter::Dispatcher::AsHashHandler->new(
            Namespaces => {
                ""    => "default-ns",
                "bar" => "foo-ns",
            },
        )
    );
    ok ref $h, "HASH";
},
@ns_tests,
sub {
    $h = $ns->playback( 
        XML::Filter::Dispatcher->new(
            Namespaces => {
                ""    => "default-ns",
                "bar" => "foo-ns",
            },
            Rules => [
                "hash( root )" => \&xvalue,
            ],
#            Debug => 1,
        )
    );
#use Data::Dumper; warn Dumper( $h );
    ok ref $h, "HASH";
},
@ns_tests,
);


plan tests => scalar @tests;

$_->() for @tests;


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
        $r = $h->$m( @{$_->[1]} ) if $h->can( $m );
    }
    return $r;
}
