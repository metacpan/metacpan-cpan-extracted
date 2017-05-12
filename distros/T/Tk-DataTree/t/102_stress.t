################################################################################
#
# $Project: /Tk-DataTree $
# $Author: mhx $
# $Date: 2008/01/11 00:18:49 +0100 $
# $Revision: 7 $
# $Snapshot: /Tk-DataTree/0.06 $
# $Source: /t/102_stress.t $
#
################################################################################
#
# Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
BEGIN { plan tests => 100 }

use Tk;
use Tk::DataTree;

eval {
  require Scalar::Util;
  *dualvar = \&Scalar::Util::dualvar;
};

if ($@) {
  print "# Scalar::Util not installed\n";
  *dualvar = sub { "$_[1] ($_[0])" };
}

my $sleep = $ENV{DATATREE_TEST_SLEEP} || 0;

my $mw = new MainWindow;
$mw->geometry("800x600");

my @dt = map {
           getwidget()->pack(-fill => 'both', -expand => 1, -side => 'left')
         } 1 .. 4;

srand 0;
my $string = 'aaaaa';

$mw->idletasks;

for (1 .. 100) {
  s/#.*//;
  /\S/ or next;
  for my $dt (@dt) {
    if (rand() < 0.1) {
      $dt->packForget;
      $dt->destroy;
      $dt = getwidget()->pack(-fill => 'both', -expand => 1, -side => 'left');
    }
    my $r = getrand();
    if (rand() < 0.5) {
      $dt->data($r);
    }
    else {
      $dt->configure(-data => $r);
    }
    $dt->autosetmode;
    $dt->configure(-undefcolor => getcolor());
    my $w = $dt->Subwidget('scrolled') || $dt;
    $w->Subwidget('normalstyle')
      ->configure(-fg => getcolor(), -background => getcolor());
    $w->Subwidget('nodestyle')
      ->configure(-fg => getcolor(), -background => getcolor());
    $w->Subwidget('activestyle')
      ->configure(-fg => getcolor(), -background => getcolor());
  }
  $mw->idletasks;
  ok($@,'');
  select undef, undef, undef, $sleep;
}

sub getwidget
{
  my $r = rand 3;
  if ($r < 1) {
    return $mw->Scrolled('DataTree', -activecolor => getcolor(),
                                     -scrollbars  => 'sw');
  }
  elsif ($r < 2) {
    return $mw->DataTree(-activecolor => getcolor());
  }
  else {
    return $mw->Scrolled('DataTree', -activecolor => getcolor(),
                                     -scrollbars  => 'e');
  }
}

sub getcolor
{
  my @hex = ('0'..'9', 'A'..'F');
  join '', '#', map { $hex[rand @hex] } 1 .. 6;
}

sub getrand
{
  my $l = shift || 0;

  my $c = rand( $l > 4 ? 5 : 7 );

  if ($c < 1) {
    return int rand 100000;
  }
  elsif ($c < 2) {
    return $string++;
  }
  elsif ($c < 3) {
    return dualvar(int rand 100000, $string++);
  }
  elsif ($c < 4) {
    return sub { log rand shift };
  }
  elsif ($c < 5) {
    return undef;
  }
  elsif ($c < 6) {
    return [ map { getrand($l+1) } 0 .. rand 10 ];
  }
  elsif ($c < 7) {
    return { map { ($string++ => getrand($l+1)) } 0 .. rand 10 };
  }
}

