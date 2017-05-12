#!perl -w

use Tk;
use Tk::ImageButton;

use strict;
use diagnostics;

my $MW = new MainWindow();

my $norm_im = $MW->Photo(-file => "quit_normal.bmp");
my $over_im = $MW->Photo(-file => "quit_over.bmp");
my $click_im = $MW->Photo(-file => "quit_clicked.bmp");
my $disable_im = $MW->Photo(-file => "quit_disabled.bmp");

my $button_text = "Enable Quit";

my $button_im2 = $MW->ImageButton(	-imagedisplay => $norm_im,
					-imageover => $over_im,
					-imageclick => $click_im,
					-imagedisabled => $disable_im,
					-state => 'disabled',
					-command => [ sub {$MW->destroy} ]
				)->pack(-side => 'right');

my $button_no = $MW->Button(	-textvariable => \$button_text,
				-width => 10,
				-command => [ sub {$button_text = button_state($button_im2)} ]
				)->pack(-side => 'left');

MainLoop;

exit;

sub button_state($)
{
	my $butt = shift;

	if ($butt->cget(-state) eq 'normal')
	{
		$butt->configure(-state => 'disabled');
		return("Enable Quit");
	}
	else
	{
		$butt->configure(-state => 'normal');
		return("Disable Quit");
	}
}



1;

