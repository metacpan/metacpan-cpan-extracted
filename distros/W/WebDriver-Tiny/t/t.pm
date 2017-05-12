package t;

use strict;
use warnings;

require WebDriver::Tiny;

sub import {
    # Turn on strict & warnings for the caller.
    strict->import;
    warnings->import;

    eval "package main; use Test::More tests => $_[1]";
}

my @reqs;

# Give the caller a reqs_are test sub.
sub main::reqs_are {
    Test::More::is_deeply( \@reqs, @_ );

    @reqs = ();
}

# Give the caller a $content so they can override.
*main::content = \( my $content = '{}' );

# Our dummy user agent just logs what the request was and returns success.
sub ua::request {
    my @args = @_[1,2];

    # Decode JSON to make testing easier. Skip empty payloads ('{}' or '[]').
    $args[2] = JSON::PP::decode_json( $_[3]{content} )
        if length $_[3]{content} > 2;

    push @reqs, \@args;

    { content => $content, success => 1 };
};

my $drv = bless [ bless( [], 'ua' ), '', '' ], 'WebDriver::Tiny';

$drv->[4] = sub { $drv->find(@_) };

# Give the caller a $drv and a $elem.
*main::drv = \$drv;

*main::elem = \bless [ $drv, 123 ], 'WebDriver::Tiny::Elements';
