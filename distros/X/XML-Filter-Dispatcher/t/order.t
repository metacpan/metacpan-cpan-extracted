#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::Filter::Dispatcher qw( :all );

my $ab = QB->new( "ab", "<a><b/></a>" );

sub d {
    my $options = @_ && ref( $_[-1] ) eq "HASH" ? pop : {};
    my ( $qb, $rules, $expected ) = @_;

    my $d = XML::Filter::Dispatcher->new(
        Rules => $rules,
        %$options,
    );

    my $got = $qb->playback( $d );
    @_ = ( $got, $expected );
    goto &ok;

}


sub r0 { 0 }
sub r1 { 1 }


my @tests = (
sub { d $ab, [ 'a'    => \&r0, 'a'    => \&r1 ], 1 },
sub { d $ab, [ 'a'    => \&r0, 'a[b]' => \&r1 ], 1 },
sub { d $ab, [ 'a[b]' => \&r0, 'a'    => \&r1 ], 1 },
sub { d $ab, [ 'a[b]' => \&r0, 'a[b]' => \&r1 ], 1 },
);

plan tests => 0+@tests;

$_->() for @tests;

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
