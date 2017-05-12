#!/usr/bin/perl
use strict;
use warnings;
use Tkx;
use Test::More tests => 2;

BEGIN { use_ok('Tkx::TclTk::Bind::IWidgets') }

my $mw = Tkx::widget->new('.');
$mw->Tkx::wm_title('Calendar Example');
my $cal = $mw->new_iwidgets__Calendar(
   -startday          => 'monday',
   -days              => 'M T W T F S S',
   -outline           => 'black',
   -weekendbackground => '#CCCCCC',
   -width             => 250,
   -height            => 200,
);

ok($cal, 'new');
