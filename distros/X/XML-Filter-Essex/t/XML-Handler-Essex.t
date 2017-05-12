use Test;

BEGIN { eval "use Test::Differences; 1" or *eq_or_diff = \&ok }

use XML::Handler::Essex;
use strict;

my $h = XML::Handler::Essex->new;

my ( $g, @doc );

{
    package Foo;

    use XML::Generator::Essex;

    $g = XML::Generator::Essex->new(
        Main    => sub { put @_ },
        Handler => $h,
    ),

    @doc = (
            start_doc,
                start( "foo1" ),
                    chars( "bar1" ),
                end,
                start( "foo2" ),
                    chars( "bar2" ),
                end,
                start( "foo3" ),
                    chars( "bar3" ),
                end,
            end_doc
    );
}

my @tests = (
sub {
    my @out;
    $h->set_main( sub { push @out, get while 1 } );
    $g->execute( @doc );
    eq_or_diff \@out, \@doc ;
},

sub {
    my @out;
    $h->set_main( sub { push @out, get while 1 } );
    $g->execute( @doc );
    eq_or_diff \@out, \@doc ;
},

sub {
    my @out;
    $h->set_main( sub { push @out, get "node()" while 1 } );
    $g->execute( @doc );
    eq_or_diff \@out, \@doc ;
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "start-document::*" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( start_document() )];
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "end-document::*" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( end_document() )];
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "start-element::*" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( <foo1> <foo2> <foo3> )];
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "end-element::*" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( </foo1> </foo2> </foo3> )];
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "*" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( <foo1>bar1</foo1> <foo2>bar2</foo2> <foo3>bar3</foo3> )];
},

sub {
    my @out;
    $h->set_main( sub { push @out, "". get "text()" while 1 } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( bar1 bar2 bar3 )];
},

sub {
    my @out;
    $h->set_main( sub {
        on "text()" => sub { push @out, "".$_[1] };
        get while 1;
    } );
    $g->execute( @doc );
    eq_or_diff
        \@out,
        [qw( bar1 bar2 bar3 )];
},

);

plan tests => 0+@tests;

$_->() for @tests;
