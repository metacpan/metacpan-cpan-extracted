#!/usr/local/lib/perl -w

use strict;

use Carp;
use Test;
use XML::Filter::Dispatcher;
use XML::SAX::PurePerl;   ## Cannot use ParserFactory; LibXML 1.31 is broken.
use UNIVERSAL;

sub d {
    my ( $rule, $expected ) = @_;

    my $options = @_ && ref( $_[-1] ) eq "HASH" ? pop : {};

    eval {
        XML::Filter::Dispatcher->new(
            Rules => [ $rule => undef ],
            %$options,
        );
    };

    ## Going to &ok like this causes ok() to report d()'s call point,
    ## making it eaier to find the failing test.
    unless ( $@ ) {
        @_ = ( "No exception thrown", $expected, $rule );
    }
    elsif ( $@ =~ $expected ) {
        @_ = ( $@, $@, $rule );
    }
    else {
        @_ = ( $@, $expected, $rule );
    }
    goto &ok;
}


my @tests = (
sub { d "1 == 2", qr/'='.*'=='/   },
sub { d "1 && 2", qr/'and'.*'&&'/ },
sub { d "1 & 2",  qr/'and'.*'&'/ },
sub { d "1 | 2",  qr/NumericConstant.*union/ },
sub { d "1 || 2", qr/'or'.*'\|\|'/ },
);

plan tests => 0 + @tests;

$_->() for @tests;

