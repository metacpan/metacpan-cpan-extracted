#!perl -w
# Demo on how to use Win32::GUI::HyperLink
#
# See the Win32::GUI::HyperLink POD documents for further
# Information
#
# Author: Robert May - robertmay@cpan.org
#
# Copyright (C) 2005..2009 Robert May
#
# This script is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

use strict;
use warnings;

use Win32::GUI 1.02 qw(MB_OK MB_ICONASTERISK);
use Win32::GUI::HyperLink;

# Some useful constants
sub CL_RED()    {0x0000FF}; # Red
sub CL_GREEN()  {0x00FF00}; # Green
sub UL_NEVER()  {0};        # Never underline link
sub UL_HOVER()  {1};        # underline link when the mouse is over the link (this is the default)
sub UL_ALWAYS() {2};        # Always underline link

my $title = "HyperLink Demo";

# A menu
my $Menu = Win32::GUI::MakeMenu(
  "&File"             => "File",
	"   > E&xit"        => { -onClick => sub { -1; }, -name => "Exit" },
  "&Help"             => "Help",
	"   > &About ..."   => { -onClick => \&AboutWindow, -name => "About" },
);

# A window with a menu
my $mw = Win32::GUI::Window->new(
	-title => $title,
	-menu => $Menu,
	-pos => [ 100, 100 ],
	-size => [ 240, 200 ],
  -resizable =>0,       # As I don't want to bother with re-drawing here!
  -maximizebox =>0,     # Ditto.
  -onTerminate => sub {-1},
);

# A status bar, where will might display the link information
my $status = $mw->AddStatusBar(
);

# Simplest usage
my $hl1 = $mw->AddHyperLink(
	-text => "http://rob.themayfamily.me.uk/perl/win32-gui/",
	-pos => [10,10],
);

# Provide text to display in the label instead of the link,
# change the colour and add callbacks to put the link info
# into the status bar.  Never underlined.
my $hl2 = $mw->AddHyperLink(
  -text => "HyperLink.pm webpage",
  -url => "http://rob.themayfamily.me.uk/perl/win32-gui/win32-gui-hyperlink",
	-foreground => CL_RED,
	-pos => [10,30],
	-onMouseIn => \&setStatus,
	-onMouseOut => \&unsetStatus,
	-underline => UL_NEVER,
);

# A differnt font
my $font = Win32::GUI::Font->new(
	-name => "Comic Sans MS", 
	-size => 14,
);

# Using a different font: it really is just like a Label.
# Always underlined, and our own onClick handler
# Alternate constructor format
my $hl3 = Win32::GUI::HyperLink->new(
	$mw,
	-text => "email author",
	-url => 'mailto:rmay@popeslane.clara.co.uk',
	-foreground => CL_GREEN,
	-pos => [10,50],
	-font => $font,
	-onMouseIn => \&setStatus,
	-onMouseOut => \&unsetStatus,
	-onClick => \&hl3Click,
	-underline => UL_ALWAYS,
);

$mw->Show();
Win32::GUI::Dialog();

exit(0);

# using MessageBox for a quick About ... implementation
sub AboutWindow
{
	$mw->MessageBox("Demonstration of Win32::GUI::HyperLink v".Win32::GUI::HyperLink->VERSION()."\r\n".
		"Running on Win32::GUI v". Win32::GUI->VERSION(). "\r\n".
		'By Robert May - robertmay@cpan.org',
		"About $title",
		MB_OK|MB_ICONASTERISK,
	);

	return 1;
}

sub setStatus
{
  my $self = shift;

  # An example of how the onMouseIn handler can be used to
  # change the window when the link is hovered over:
  # in this case, display the link in the status bar.
  $status->Text($self->Url());

  return 1;
}

sub unsetStatus
{
  my $self = shift;

  # An example of how the onMouseOut handler can be used to
  # change the window when the mouse leaves the link area:
  # in this case clearing the status bar text
  $status->Text("");

  return 1;
}

sub hl3Click
{
  my $self = shift;

  # An example of customising the behaviour when the link is clicked:
  # in this case, print a message, and then invoke the default handler.
  # You need to explicitly invoke the default handler if you want the
  # link to launch in your own handler.

  # print our message:
  print "You have clicked the link.\n";

  # invoke the default handler to launch the link:
  $self->Launch();

  return 1;
}
