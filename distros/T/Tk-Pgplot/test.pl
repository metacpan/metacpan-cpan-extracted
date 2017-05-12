#!/usr/bin/perl -w

use strict;

use blib;

use Tk;
use Tk::Pgplot;
use PGPLOT;

# Start by testing that we can find the ptk pgplot driver
# If it is not present, something is wrong

my ($ndrivers,$n,$type,$tlen,$descr,$dlen,$inter, $dummy);
pgqndt($ndrivers);

my $foundit=0;
for $n (1..$ndrivers) {
  pgqdt($n,$type,$dummy,$dummy,$dummy,$dummy);
  if (uc($type) eq '/PTK') {
    $foundit = 1;
    last;
  }
}
if (!$foundit) { # Not present in list of drivers
warn<<EOF

*** Could not find PTK pgplot driver ***

This is probably caused by linking with the wrong version of pgplot 
(try "ldd blib/arch/auto/Tk/Pgplot/Pgplot.so") or a compilation mismatch.
Have you compiled pgperl since you patched pgplot? 

EOF
  ;
exit 0;
}

sub Plotit() {
  my $img="";
  open(IMG,"test.img") || die "Data file test.img not found";
  read(IMG, $img, 32768);
  close(IMG);

  my @image = unpack("n*",$img);

  if (pgopen('pgtest/ptk') <=0) {
    die "Could not open pgplot device\n";
  }

  pgsci(3);
  pgwnad(12000,13000,13000,12000);

  my @tr=(12000,8,0,12000,0,8);

  pgimag(\@image,128,128,1,128,1,128,0,5000,\@tr);
  pglabel("\\ga","\\gd","Galaxy");
  pgtbox("ZYHBCNST",0,0,"ZYDBCNST",0,0);

  my @l=(0,0.004,0.502,0.941,1); 
  my @r=(0,0,1,1,1); 
  my @g=(0,0,0.2,1,1); 
  my @b=(0,0.2,0,0.1,1);

  pgctab(\@l,\@r,\@g,\@b,5,1,0.5);

  pgsci(4); pgsls(1);
  my @cont = (-1,1000,2000,3000,4000,5000);
  pgcons(\@image, 128, 128, 1,128,1,128, \@cont, 6, \@tr);

  for(@cont){
    pgconl(\@image, 128, 128, 1,128,1,128, $_, \@tr, $_,200,100);
  }

  my @xbox;
  my @ybox;
  pgsci(4);
  pgscf(2);
  pgqtxt(12125,12100,45,0.5,'PGPLOT...',\@xbox,\@ybox);
  pgpoly(4,\@xbox, \@ybox);
  pgsci(7);
  pgptxt(12125,12100,45,0.5,'PGPLOT...');

  pgclos();
}

my $mw = MainWindow->new;

my $quit = $mw->Button(-text    => 'Quit',
		      -command => sub {exit;})->pack;

my $plot = $mw->Button(-text    => 'Plot',
		      -command => \&Plotit)->pack;

my $w = $mw->Frame()->pack;
# This is NOT a good choice of colours!
my $pgplot = $w->Pgplot(-name => 'pgtest',
			-width => '15c',
			-height => '15c',
			-bg => 'ivory',
			-fg => 'blue',
			-maxcolors => 64,
			-cursor => 'hand2',
			-relief => 'groove',
			-borderwidth => 5,
			-highlightbackground => 'red',
			-highlightcolor => 'green',
			-takefocus => 1
		       );

# Respond to key strokes
$pgplot->bind('<KeyPress>' => [sub {print "Pressed $_[1]\n"}, Ev('A')]);

# Add scroll bars. This does not seem to work see the demo
my $xscroll = $w->Scrollbar(-orient => 'horizontal',
			     -command => ['xview', $pgplot]);
my $yscroll = $w->Scrollbar(-orient => 'vertical',
			     -command => ['yview', $pgplot]);


$pgplot->configure(-xscrollcommand => ['set', $xscroll]);
$pgplot->configure(-yscrollcommand => ['set', $yscroll]);

$xscroll->pack(-side => 'bottom',
	       -fill => 'x');
$yscroll->pack(-side => 'right',
	       -fill => 'y');
$pgplot->pack(-side => 'left',
	      -fill => 'both',
	      -expand => 1);

MainLoop;

