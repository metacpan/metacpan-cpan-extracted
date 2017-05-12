# A Titled Frame widget.
#!/usr/local/bin/perl -w
use strict;
use Tk;
use Tk::TFrame;

my $mw = Tk::MainWindow->new;

my $frame = $mw->TFrame(
	-label => [
		-text => 'Title',
		-borderwidth => 2,
		-relief => 'groove'
	],
	-borderwidth => 2,
	-relief => 'groove'
);

$frame->Label(-text => 'Left')->pack(-side => 'left');
$frame->Label(-text => 'Right')->pack(-side => 'right');
$frame->Label(-text => 'Top')->pack(-side => 'top');
$frame->Label(-text => 'Bottom')->pack(-side => 'bottom');

$frame->pack(-fill => 'both', -expand => 1);

Tk::MainLoop;
__END__
