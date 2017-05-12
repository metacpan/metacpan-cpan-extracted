use Win32::MultiMedia::Joystick;
use Tk;
use strict;
use Tk::Canvas;

my $accel = .001;
my $dead = 3000;

my $joy = Win32::MultiMedia::Joystick->new();
if (!$joy) { die $joy->error," $!\n"; }

my $mw = Tk::MainWindow->new;
my $scr = $mw->Canvas->pack(-fill=>'both',-expand=>1);


sub MyMainLoop
{
	$mw->update;
	my ($x,$y,$dx,$dy);
	my $Xdiff = ($joy->Xmax - $joy->Xmin)/2;
	my $Ydiff = ($joy->Ymax - $joy->Ymin)/2;
	$x=$mw->width/2;
	$y=$mw->height/2;
	$dx=$dy=0;
	
	
	my ($x1,$y1,$x2,$y2);
	my $ln = $scr->createLine($x-10,$y,$x+20,$y);
	while ($mw)
	{
		$joy->update;
		$x = $Xdiff - $joy->X;
		$y = $Ydiff - $joy->Y;
		$dx -= $accel if $x>$dead;
		$dx += $accel if $x<-$dead;
		$dy -= $accel if $y>$dead;
		$dy += $accel if $y<-$dead;
		if ($joy->B4) 
		{
			$dx -= $accel if $dx>0;
			$dx += $accel if $dx<0;
			$dy -= $accel if $dy>0;
			$dy += $accel if $dy<0;
		}
		if ($joy->B1)
		{
			print $mw->state,"\n";
			print "hi\n";
		}
		$scr->move($ln,$dx,$dy);
		($x1,$y1,$x2,$y2) = $scr->bbox($ln);
		if ($x2>$scr->width) {	$scr->move($ln,-$scr->width,0)}
		if ($x1<0) {	$scr->move($ln,$scr->width,0)}
		if ($y2>$scr->height) {	$scr->move($ln,0,-$scr->height)}
		if ($y1<0) {	$scr->move($ln,0,$scr->height)}
		$mw->update;
	}
}

MyMainLoop;


