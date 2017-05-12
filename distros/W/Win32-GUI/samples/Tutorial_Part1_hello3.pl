#!perl -w
use strict;
use warnings;

use Win32::GUI();

my $text = defined($ARGV[0]) ? $ARGV[0] : "Hello, world";

my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 100,
	-height => 100,
	-text   => 'Perl',
);

# Create a new Win32::GUI::Font object with which
# we'll draw the text
my $font = Win32::GUI::Font->new(
	-name => "Comic Sans MS", 
	-size => 24,
);

my $label = $main->AddLabel(
	-text       => $text,
	-font       => $font,    # use the font we created
	-foreground => 0x0000FF, # use red text
);


$main->Resize(
	$label->Width()  + $main->Width()  - $main->ScaleWidth(),
	$label->Height() + $main->Height() - $main->ScaleHeight()
);

$main->Show();
Win32::GUI::Dialog();
exit(0);

sub Main_Terminate {
	return -1;
}
