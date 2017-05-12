#!perl

use strict;
use warnings;

use Test::More;
use Test::Trap;

my @r;


@r = trap { ::PKG->tattle() };
$trap->return_is( 0, 'A::Base', "$::PKG\::import not called" );

@r = trap { tattle() };
$trap->die_like( qr/undefined subroutine/i,
    "no import of $::PKG\::tattle" );

@r = trap { ::PKG->tattle_ok() };
$trap->return_is( 0, 'ok: A::Base', "$::PKG\::import not called" );

trap { tattle_ok() };
$trap->die_like( qr/undefined subroutine/i,
    "no import of $::PKG\::tattle_ok" );


trap { ::PKG->import('tattle_ok') };
$trap->did_return("explicit import of $::PKG\::tattle_ok");

@r = trap { tattle_ok() };
$trap->return_like( 0, qr/ok: $::PKG/,
    "explicit import of $::PKG\::tattle_ok value" );
