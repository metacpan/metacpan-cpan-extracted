#!/usr/bin/env perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 3;
use Test::Exception;

use WWW::ItsABot qw/is_a_bot/;

do {
    no warnings 'redefine';
    *WWW::ItsABot::get = sub($) {
        my $url = shift;
        if ( $url =~ m!/User/bot! ){
            return "bot,6635,0,753,True,8.81142098274,0.0,2009-06-15 04:35:31.410268\n";
        } elsif ($url =~ m!/User/dontexist!) {
            return "{}\n";
        } else {
            return "user,187,150,662,False,0.509063444109,0.802139037433,2009-06-15 06:03:57.740732\n";
        }
    };
};

cmp_ok( is_a_bot('bot'),'==', 1, 'bots are bots' );

cmp_ok( is_a_bot('dukeleto'),'==', 0, 'should not be a bot' );

throws_ok( sub { is_a_bot('dontexist') }, qr/user does not exist/, 'Nonexistent users throw an error');
