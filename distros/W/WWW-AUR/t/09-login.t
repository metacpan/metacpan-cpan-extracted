#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More tests => 8;

use WWW::AUR::Login;

my $user   = $ENV{'AUR_USER'};
my $passwd = $ENV{'AUR_PASSWD'};
my $pkg    = $ENV{'AUR_PKG'};

SKIP: {
    my $msg = <<'END_MSG';
Set the AUR_USER, AUR_PASSWD, AUR_PKG env. vars to test login
END_MSG

    unless ( $user && $passwd && $pkg ) {
        diag $msg;
        skip $msg, 8;
    }

    my $login = WWW::AUR::Login->new( $user, $passwd );
    ok $login;

    ok $login->adopt( $pkg );
    ok $login->disown( $pkg );
    ok $login->vote( $pkg );
    ok $login->unvote( $pkg );
    ok $login->flag( $pkg );
    ok $login->unflag( $pkg );

    my @packages = $login->my_packages;
    ok @packages > 0, 'successfully found your owned packages';
};
