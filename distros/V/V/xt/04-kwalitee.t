#!/usr/bin/perl -I.

use strict;
use warnings;

use t::Test::abeltje;

$ENV{RELEASE_TESTING} = 1;
use Test::Kwalitee "kwalitee_ok";

kwalitee_ok (qw(
    -has_meta_yml
    -no_symlinks
    ));

abeltje_done_testing ();
