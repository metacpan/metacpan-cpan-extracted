#!/usr/bin/env perl

BEGIN {
    $ENV{AMW_DEBUG} = 1;
}

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Test::More tests => 2;

my $wd = Path::Tiny->tempdir;

my $muse = $wd->child('muse.muse');
$muse->spew_utf8(<<'MUSE');
#title test

Test [[xxx.jpg]]
MUSE


my $c = Text::Amuse::Compile->new(epub => 1, html => 1);
$c->compile("$muse");

my $status = $wd->child('muse.status');
ok $status->exists;
diag $status->slurp_utf8;
like $status->slurp_utf8, qr/xxx\.jpg does not exist/;
