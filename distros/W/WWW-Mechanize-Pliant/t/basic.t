#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use vars qw( $class );

BEGIN {
    $class = 'WWW::Mechanize::Pliant';
    use_ok $class;
}

# ------------------------------------------------------------------------

{
    my $cacher = $class->new;
    isa_ok( $cacher => $class );
}
