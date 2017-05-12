#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::SAX::PurePerl;
use XML::Filter::Dispatcher qw( :all );
use XML::SAX::Writer;

use UNIVERSAL;

my( $doc_root_out );

my $doc_string = "<a><b>B<c><d>D</d></c></b><b><c>C</c></b></a>";
my $doc = QB->new( "doc", $doc_string );

my @out;
sub p { push @out, join scalar xvalue, "(", ")" };

sub t {
    $doc_root_out = undef;
    @out = ();
    $doc->playback( XML::Filter::Dispatcher->new( @_ ) );
}


sub my_ok {
    my ( $got, $expected ) = @_;

    @_ = ( 1 )
        if $got =~ $expected;

    goto &ok;
}




my @tests = (
sub {
    t(
        Rules => [ 'a[b]' => [ '1' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(1)";
},

sub {
    t(
        Rules => [ 'a[b]/b[c]' => [ '1' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(1),(1)";
},

sub {
    t(
        Rules => [ 'string(a/b)' => \&p ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(BD)";
},
sub {
    t(
        Rules => [ 'a[b]' => [ 'string()' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(BDC)";
},

sub {
    t(
        Rules => [ 'b[c]' => [ '1' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(1),(1)";
},
sub {
    t(
        Rules => [ 'b[not(c)]' => [ '1' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "";
},
sub {
    t(
        Rules => [ 'b[not(c/d)]' => [ '1' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(1)";
},
sub {
    t(
        Rules => [ 'b[not(c/d)]' => [ 'string()' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(C)";
},
sub {
    t(
        Rules => [ 'b[c/d]' => [ 'string()' => \&p ] ],
#        Debug => 1,
    );
    ok join( ",", @out ), "(BD)";
},
#TODO:
#sub {
#    t(
#        Rules => [ 'b[c[d]]' => [ '1' => \&p ] ],
#        Debug => 1,
#    );
#    ok join( ",", @out ), "(1)";
#},
#sub {
#    t(
#        Rules => [ 'b[c[d]]' => [ 'string()' => \&p ] ],
#        Debug => 1,
#    );
#    ok join( ",", @out ), "(BD)";
#},
);

plan tests => scalar @tests;

$_->() for @tests;

package ResultTester;

BEGIN { @ResultTester::ISA = qw( XML::SAX::Base ); }

sub end_document { "result string" }


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
    if ( -e $cache_fn ) {
        my $old_self = do $cache_fn;
        return $old_self if defined $old_self
            && shift @$old_self eq $doc;
        warn "$!$@" unless defined $old_self;
        unlink $cache_fn;
    }

    push @$self, $doc;

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

    shift @$self;

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
