use strict;

use Test;
use XML::SAX::Machines qw( Machine );

package My::Id::Adder;

    ## Identical to code in t/11byrecord.t

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

package main;

my $m;

my $out;

my @tests = (
sub {
    $out = "";
    $m = Machine(
        [ Intake => "XML::Filter::DocSplitter" => qw( A )      ],
        [ A      => "My::Id::Adder"            => qw( Merger ) ],
        [ Merger => "XML::Filter::Merger"      => qw( Output ) ],
        [ Output => \$out ],
    );
    $m->Intake->set_aggregator( $m->Merger );
    ok $m->isa( "XML::SAX::Machine" );
},

sub {
    $out = "";
    ok $m->parse_string( "<foo>a<bar>b</bar>c<baz>d</baz>e<bat>f</bat>g</foo>" );
},

sub {
$out =~ s/^<\?.*?\?>//;
    $out =~
     m{<foo\s*>a<bar\s+id=['"]1["']\s*>B</bar>c<baz\s+id=['"]2["']\s*>D</baz>e<bat\s+id=['"]3["']\s*>F</bat>g</foo\s*>}
        ? ok 1
        : ok qq{this output    $out},
             qq{something like <foo>a<bar id='1'>b</bar>c<baz id='2'>d</baz>e<bat id='3'>f</bat>g</foo>} ;
},
);

plan tests => scalar @tests;

$_->() for @tests;

