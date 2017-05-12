#!/usr/local/bin/perl -w

use strict;

use Test;
use XML::SAX::Machines qw( Pipeline ByRecord );

package My::Id::Adder;
    ## Identical to code in t/10docsplitter.t

    use vars qw( @ISA );
    @ISA = qw( XML::SAX::Base );

    use XML::SAX::Base;

    my $id;

    sub start_element {
        my $self = shift;
        my ( $elt ) = @_;

        $elt->{Attributes}->{id} = {
            Name      => "id",
            LocalName => "id",
            Value     => ++$id,
        };

        $self->SUPER::start_element( @_ );
    }

    sub characters {
        my $self = shift;
        my ( $data ) = @_;

        $data->{Data} = uc $data->{Data};

        $self->SUPER::characters( @_ );
    }

## This is the example from XML::SAX::ByRecord POD.
package My::Filter::Uc;

    use vars qw( @ISA );
    @ISA = qw( XML::SAX::Base );

    use XML::SAX::Base;

    sub characters {
        my $self = shift;
        my ( $data ) = @_;
        $data->{Data} = uc $data->{Data};
        $self->SUPER::characters( @_ );
    }

package main;

my $m;

my $out;


my @tests = (
sub {
    $out = "";
    $m = Pipeline(
        ByRecord( "My::Id::Adder" ),
        \$out,
    );
    ok $m->isa( "XML::SAX::Machine" );
},

sub {
    $out = "";
    $m->parse_string( "<foo>a<bar>b</bar>c<baz>d</baz>e<bat>f</bat>g</foo>" );
    ok 1;
},

sub {
    $out =~
    m{<foo\s*>a<bar\s+id=['"]1["']\s*>B</bar>c<baz\s+id=['"]2["']\s*>D</baz>e<bat\s+id=['"]3["']\s*>F</bat>g</foo\s*>}
        ? ok 1
        : ok qq{this outout    $out},
             qq{something like <foo>a<bar id='1'>B</bar>c<baz id='2'>D</baz>e<bat id='3'>F</bat>g</foo>} ;
},

sub {
    $out = "";
    $m = Pipeline(
        ByRecord( "My::Filter::Uc" ),
        \$out,
    );
    $m->parse_string( "<root>a<rec>b</rec>c<rec>d</rec>e<rec>f</rec>g</root>" );
    $out =~
    m{<root\s*>a<rec\s*>B</rec>c<rec\s*>D</rec>e<rec\s*>F</rec>g</root\s*>}
        ? ok 1
        : ok qq{this outout    $out},
             qq{something like <root>a<rec id='1'>B</rec>c<rec id='2'>D</rec>e<rec id='3'>F</rec>g</root>} ;
},
);

plan tests => scalar @tests;

$_->() for @tests;
