#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'Tie::DBIx::Class' );

ok(tie(my %test,'Tie::DBIx::Class',undef,'foo','bar'),'tie');
like(tied(%test),qr/^\QTie::DBIx::Class=HASH(\E/,'Check tied');
