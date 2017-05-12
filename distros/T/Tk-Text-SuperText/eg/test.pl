#!/usr/bin/perl -w

use strict;
use warnings;
use 5.012;
use File::Spec;
use FindBin qw/$Bin/;
use lib File::Spec->catdir($Bin, '..', 'lib');
use Tk;
use Tk::Text::SuperText;

say $Tk::Text::SuperText::VERSION;

my $mw = Tk::MainWindow->new;

my $text = $mw->Scrolled('SuperText',
	-scrollbars => 'se',
	-wrap => 'none',
	-borderwidth => 0,
	-width => 80,
	-height => 40,
	-indentmode => 'auto',
	-background => 'white',
	-foreground => 'blue',
);

$text->pack('-fill' => 'both','-expand' => 'true');
$text->focus;

#$text->bind('Tk::Text::SuperText','<<pippo>>',\&pippo);
#$text->eventAdd('<<pippo>>','<Control-p>','<Control-Key-1>');

$mw->MainLoop;
exit(0);

sub pippo {
	my $w = shift;
	
	my $s=$w->cget('-matchingcouples');
	print (defined $s ? $s :'undef');
	print "\n";
}
