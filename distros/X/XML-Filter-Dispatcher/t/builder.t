#!/usr/local/lib/perl -w

use strict;

use Carp;
use Test;
use XML::Filter::Dispatcher qw( :all );
use UNIVERSAL;

my $h;

my $ab = QB->new( "ef", <<'XML_END' );
<root a="A"><e aa1="AA1" aa2="AA2"><f>B1</f><f>B2</f></e></root>
XML_END

my $ns = QB->new( "nsef", <<'XML_END' );
<root
    xmlns="default-ns"
    xmlns:foo="foo-ns"
    a="A"
    foo:a="FOOA"
><e aa1="AA1" foo:aa1="AA2"><f>B1</f><foo:f>B2</foo:f></e></root>
XML_END

my @tests = (
sub {
    $h = $ab->playback( XML::Filter::Dispatcher->new(
        Rules => [
            ## Any leaf nodes get stringified
            '@*'            => [ "string()" => sub { xadd } ],

            ## Any leaf nodes get stringified
            '*'             => [ "string()" => sub { xadd } ],

            ## This next one is where we'd new any contained objects.
            '*[*]'          => sub { xset {} },

            ## This next one is where we would new the root object.
            '/*'              => sub { xset {} },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 2,
    ) );
    ok ref $h, "HASH";
},

sub { ok $h->{a}->[0],      "A"  },
sub { ok $h->{e}->{f}->[0], "B1" },
sub { ok $h->{e}->{f}->[1], "B2" },

sub {
    $h = $ns->playback( XML::Filter::Dispatcher->new(
        Rules => [
            ## Any leaf nodes get stringified
            '@*'            => [ "string()" => sub { xadd } ],

            ## Any leaf nodes get stringified
            '*'             => [ "string()" => sub { xadd } ],

            ## This next one is where we'd new any contained objects.
            '*[*]'          => sub { xset {} },

            ## This next one is where we would new the root object.
            '/*'              => sub { xset {} },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 1,
    ) );
    ok ref $h, "HASH";
},

sub { ok $h->{a}->[0],      "A"  },
sub { ok $h->{e}->{f}->[0], "B1" },
sub { ok $h->{e}->{f}->[1], "B2" },

sub {
    $h = $ns->playback( XML::Filter::Dispatcher->new(
        Rules => [
            ## Any leaf nodes get stringified
            '*/@*'            => [ "string()" => sub { xadd } ],

            '@xmlns'          => undef,

            ## This next one is where we would new the root object.
            '/*'              => sub { xset [] },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 1,
    ) );
    ok ref $h, "ARRAY";
},

sub { ok $h->[0], "A" },
sub { ok $h->[1], "FOOA" },
sub { ok $h->[2], "foo-ns" },
sub { ok $h->[3], "AA1" },
sub { ok $h->[4], "AA2" },

sub {
    $h = $ab->playback( XML::Filter::Dispatcher->new(
        Namespaces => { none => "" },

        Rules => [
            ## Any leaf nodes get stringified
            '@*'  => [ "string()" => sub { xadd } ],

            ## This next one is where we would new the root object.
            '/*'              => sub { xset [] },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 2,
    ) );
    ok ref $h, "ARRAY";
},
sub { ok $h->[0], "A" },
sub { ok $h->[1], "AA1" },
sub { ok $h->[2], "AA2" },

sub {
    $h = $ab->playback( XML::Filter::Dispatcher->new(
        Namespaces => { none => "" },

        Rules => [
            ## Any leaf nodes get stringified
            '@none:*'  => [ "string()" => sub { xadd } ],

            ## This next one is where we would new the root object.
            '/*'              => sub { xset [] },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 1,
    ) );
    ok ref $h, "ARRAY";
},

sub { ok $h->[0], "A" },
sub { ok $h->[1], "AA1" },
sub { ok $h->[2], "AA2" },

sub {
    $h = $ab->playback( XML::Filter::Dispatcher->new(
        Namespaces => { none => "" },

        Rules => [
            ## Any leaf nodes get stringified
            'none:*/@none:*'  => [ "string()" => sub { xadd } ],

            ## This next one is where we would new the root object.
            '/*'              => sub { xset [] },

            ## And here's where we return the root object
            '/end-element::*' => sub { xpop },
        ],
#        Debug => 1,
    ) );
    ok ref $h, "ARRAY";
},

sub { ok $h->[1], "AA1" },
sub { ok $h->[2], "AA2" },

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
