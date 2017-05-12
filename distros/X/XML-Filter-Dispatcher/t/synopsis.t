#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::Filter::Dispatcher qw( :all );
use XML::SAX::PurePerl;
use XML::SAX::Writer;

## PurePerl is slow, so only run it once.
my $d = QB->new( <<XML_END );
  <d>
    <description>1</description>
    <description>2</description>
    <description>3</description>
    <snarf>[<sniff/>]</snarf>
    <foo bar="baz"/>
    <hic id="12a">12A</hic>
    <hic id="12b">12B</hic>
  </d>
XML_END

my @v;
sub handle_foo_start_tag { push @v, "<".xvalue->{Name}.">" }
sub handle_bar_attr      { push @v, xvalue->{Name}."=".xvalue->{Value} }
sub handle_hic           { push @v, "<".xvalue->{Name}.">" }


sub run { $d->playback( shift ) }

my @out;
my $out;

my @tests = (
sub {
    my $handler = XML::SAX::Writer->new( Output => \$out );
    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'foo'               => \&handle_foo_start_tag,
                '@bar'              => \&handle_bar_attr,
    
                ## Send any <foo> elts and their contents to $handler
                'snarf//self::node()'  => $handler,

                ## Print the text of all <description> elements
                'description' 
                        => [ 'string()' => sub { push @out, xvalue } ],

#                'hic[@id=$id]'      => \&handle_hic,
            ],

            Vars => {
                "id" => [ string => "12a" ],
            },
        )
    );

    ok int @out, 3;
},

sub { ok $out[0], 1 },
sub { ok $out[1], 2 },
sub { ok $out[2], 3 },

sub { ok $out, qr{<snarf\s*>\[<sniff\s*/>\]</snarf>} },

sub { ok int @v, 2 },
sub { ok $v[0], "<foo>" },
sub { ok $v[1], "bar=baz" },

);

plan tests => scalar @tests;

$_->() for @tests;

## This quick little buffering filter is used to save us the overhead
## of a parse for each test.  This saves me sanity (since I run the test
## suite a lot), allows me to see which tests are noticably slower in
## case something pathalogical happens, and keeps admins from getting the
## impression that this is a slow package based on test suite speed.
package QB;
use vars qw( $AUTOLOAD );

sub new {
    my $self = bless [], shift;
    my $p = XML::SAX::PurePerl->new( Handler => $self );
    $p->parse_string( shift );
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
    for ( @$self ) {
        my $m = $_->[0];
        no strict "refs";
        $h->$m( @{$_->[1]} );
    }
}
