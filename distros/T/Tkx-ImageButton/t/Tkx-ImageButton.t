#!/usr/bin/perl
use strict;
use warnings;
use Tkx;
use Test::More tests => 2;

BEGIN { use_ok('Tkx::ImageButton') }

my $mw = Tkx::widget->new('.');
my $sp = $mw->new_tkx_ImageButton();
ok($sp, 'new');
