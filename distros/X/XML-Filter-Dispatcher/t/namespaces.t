#!/usr/local/lib/perl -w

use strict;

use Carp;
use Test;
use XML::Filter::Dispatcher qw( :all );
my $has_xsw;
BEGIN { $has_xsw = eval "require XML::SAX::Writer"; }
use UNIVERSAL;

my $ns_doc = <<'XML_END';
<root
    xmlns:foo="foo-ns"
    a="A"
    foo:a="FOOA"
><e aa1="AA1" foo:aa1="AA2"><f>B1</f><foo:f>B2</foo:f></e></root>
XML_END

my $ns = QB->new( "nsef", $ns_doc );

my @out;

my @tests = (
sub {
    @out = ();
    $ns->playback( XML::Filter::Dispatcher->new(
        Namespaces => {
            goo  => "foo-ns",
        },
#        Debug => 2,
        Rules => [
            'root'  => sub { push @out, "root"  },
            '@goo:a'=> sub { push @out, "foo:a" },
            'goo:f' => sub { push @out, "foo:f" },
            'f'     => sub { push @out, "f"     },
        ],
    ) );
    ok 1;
},

sub { ok int @out, 4; },
sub { ok $out[0], "root",  "out[0]" },
sub { ok $out[1], "foo:a", "out[1]" },
sub { ok $out[2], "f",     "out[2]" },
sub { ok $out[3], "foo:f", "out[3]" },

sub {
    @out = ();
    $ns->playback( XML::Filter::Dispatcher->new(
        Namespaces => {
            none => "",
        },
        Rules => [
            'none:*'  => sub { push @out, $_[1]->{Name} },
            'none:f'  => sub { push @out, "none:" . $_[1]->{Name} },
        ],
    ) );
    ok 1;
},

sub { ok int @out, 3 },
sub { ok $out[0], "root",   "out[0]" },
sub { ok $out[1], "e",      "out[1]" },
sub { ok $out[2], "none:f", "out[2]" },

sub {
    @out = ();
    $ns->playback( XML::Filter::Dispatcher->new(
        Namespaces => {
            none => "",
        },
        Rules => [
            'none:*/@none:*'  => sub { push @out, $_[1]->{Name} },
        ],
    ) );
    ok 1;
},

sub { ok int @out, 2 },
sub { ok $out[0], "a",   "out[0]" },
sub { ok $out[1], "aa1", "out[1]" },

sub {
    my @stack;
    my $prefix_count = 0;
    $ns->playback( XML::Filter::Dispatcher->new(
        Namespaces => {
            goo  => "foo-ns",
        },
#        Debug => 1,
        Rules => [
            'start-document::*|node()'  => sub {
                return unless xevent_type =~ /^(start|end)_/;
                ++$prefix_count if xevent_type =~ /prefix/;
                push @stack, xevent_type;
            },
            'end-document::*|end::node()' => sub {
                return unless xevent_type =~ /^(start|end)_/;
                die "tracking stack underflowed" unless @stack;
                pop @stack;
            },
        ],
    ) );
    ok "$prefix_count:" . join( ",", @stack ), "1:";
},

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
