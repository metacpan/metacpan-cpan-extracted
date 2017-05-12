#!/usr/bin/perl
use strict;
use warnings;
use Tkx;
use Test::More tests => 2;

BEGIN { use_ok('Tkx::TclTk::Bind::IWidgets') }

my $mw = Tkx::widget->new('.');
$mw->Tkx::wm_title('Buttonbox Example');
my $bbox = $mw->new_iwidgets__buttonbox(
   -padx => 10,
   -pady => 10,
);

ok($bbox, 'new');
