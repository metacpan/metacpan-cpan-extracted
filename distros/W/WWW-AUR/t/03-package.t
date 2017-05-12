#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More tests => 2;

use WWW::AUR::Package;

eval { WWW::AUR::Package->new( q{this-package-doesn't-exist} ); };
like $@, qr/Failed to find package/;

my $pkg = WWW::AUR::Package->new( 'perl-www-aur' );
ok $pkg;
