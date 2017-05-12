#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(:all);

local $SIG{__WARN__} = sub {
    chomp(my $m = shift);
    fail "This thing must not generate a single warning, but it did: ->$m<-";
};

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

is( $t->compile(q/<%%>/), EMPTY_STRING, 'Test edge case' );
