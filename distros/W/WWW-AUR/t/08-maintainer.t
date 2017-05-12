#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More tests => 4;

use WWW::AUR::Maintainer;

my $who = WWW::AUR::Maintainer->new( 'jnbek' );
ok $who;

my $found = 0;
for my $pkg ( $who->packages ) {
    if ( $pkg->name eq 'perl-www-aur' ) { $found = 1; }
}
ok $found, 'found perl-www-aur, owned by jnbek';

my $pkg = WWW::AUR::Package->new( 'perl-moose' );
ok $pkg, 'looked up perl-moose package';
my $maintainer = $pkg->maintainer;
ok $maintainer->name eq 'jnbek', 'perl-moose is owned by jnbek';
