use Tk;
use Tk::Radiobutton;
use Tk::Checkbutton;
use Tk::StyledButton;
use Tk::LabEntry;
use Tk::Font;

use strict;
use warnings;

my $style = 'shiny';
my $angle = 0.25;
my $slots = 30;
my $color = '#4D004D00B300';
my $fullcolor = '#4D004D00B300(65535, 0, 0)';
my $textcolor = 'black';
my $fulltextcolor = 'black(0, 0, 0)';
my $disperse = 0.8;
my $shape = 'oval';
my $scrolled = 0;
my $text;
my $image;
my $gd;
my $topbtn = 0;

my $hasgd;
my $hasfontdlg;
my $fontinfo;

eval {
	require GD;
	require GD::Text;
};

$hasgd = 1 unless $@;
#
#	try to set the font directory
#
GD::Text->font_path($ENV{SYSTEMROOT} . '\fonts')
	if $hasgd && ($^O eq 'MSWin32');

eval {
	require Tk::StyledFontDlg;
};

$hasfontdlg = 1 unless $@;

my @grouped = ([],[],[]);

my $mw = MainWindow->new();

my @demobtns;
my $canframe = $mw->Frame()->pack(-side => 'top', -fill => 'both', -expand => 1);
my $cmdframe = $mw->Frame()->pack(-side => 'bottom');

my $colorbtn = $cmdframe->StyledButton(
	-style => 'shiny',
	-shape => 'oval',
	-text => 'Button Color',
	-background => $color,
	-command => sub { colorDialog(); } )
	->grid(-column => 0, -row => 0);

$cmdframe->Label(-textvariable => \$fullcolor)->grid(-column => 1, -row => 0);

my $textcolorbtn = $cmdframe->StyledButton(
	-style => 'shiny',
	-shape => 'oval',
	-text => 'Text Color',
	-background => $textcolor,
	-command => sub { textColorDialog(); } )
	->grid(-column => 0, -row => 1);

$cmdframe->Label(-textvariable => \$fulltextcolor)->grid(-column => 1, -row => 1);

my $fontbtn = $cmdframe->StyledButton(
	-style => 'shiny',
	-shape => 'oval',
	-text => '  Font  ',
	-command => sub { setButtonFont(); } )
	->grid(-column => 0, -row => 3);

$cmdframe->Label(-textvariable => \$fontinfo)->grid(-column => 1, -row => 3);

$fontbtn->configure(-state => 'disabled')
	unless $hasfontdlg;

my $i = 1;
$cmdframe->Label(-text => 'Button style:')->grid(-column => 0, -row => 4);
$cmdframe->Radiobutton(
	-text => $_,
	-value => $_,
	-variable => \$style)
	->grid(-column => $i++, -row => 4)
	foreach ('flat', 'round', 'shiny', 'gel');

$cmdframe->Label(-text => 'Button shape:')->grid(-column => 0, -row => 5);

$i = 1;
$cmdframe->Radiobutton(
	-text => $_,
	-value => $_,
	-variable => \$shape)
	->grid(-column => $i++, -row => 5)
	foreach ('rectangle', 'round', 'oval', 'folio', 'bevel');

$i = 1;
$cmdframe->Label(-text => 'Tab Alignment:')->grid(-column => 0, -row => 6);
$cmdframe->Radiobutton(
	-text => $_,
	-value => $_,
	-variable => \$style)
	->grid(-column => $i++, -row => 6)
	foreach ('ne', 'nw', 'se', 'sw');

$i = 1;
$cmdframe->Radiobutton(
	-text => $_,
	-value => $_,
	-variable => \$style)
	->grid(-column => $i++, -row => 7)
	foreach ('en', 'es', 'wn', 'ws');

$cmdframe->Label(-text => 'Dispersion:')
	->grid(-column => 0, -row => 8, -sticky => 'e');

$cmdframe->Scale(
	-orient => 'horizontal',
	-digits => 4,
	-from => 0.0,
	-to => 1.0,
	-troughcolor => 'white',
	-resolution => 0.01,
	-showvalue => 1,
	-variable => \$disperse,
	-width => 10,
	-length => 250)
	->grid(-column => 1, -columnspan => 4, -row => 8, -sticky => 'w');

$cmdframe->Label(-text => 'Angle:')->grid(-column => 0, -row => 9, -sticky => 'e');
$cmdframe->Scale(
	-orient => 'horizontal',
	-digits => 4,
	-from => 0.0,
	-to => 1.0,
	-troughcolor => 'white',
	-resolution => 0.01,
	-showvalue => 1,
	-variable => \$angle,
	-width => 10,
	-length => 250)
	->grid(-column => 1, -columnspan => 4, -row => 9, -sticky => 'w');

my $le = $cmdframe->LabEntry(
	-label => 'Button text:',
	-labelPack => [ qw/-side left -anchor w/],
	-bg => 'white',
	-textvariable => \$text,
	-font => [ -family => 'arial', -size => 12, -weight => 'bold' ])
	->grid(-column => 0, -row => 10, -columnspan => 5);

my $font = $le->cget(-font);

$fontinfo = join('-', $font->actual(-family), $font->actual(-size), $font->actual(-weight), $font->actual(-slant));

$cmdframe->Checkbutton(
	-text => 'Add image',
	-variable => \$image)
	->grid(-column => 0, -row => 11, -columnspan => 2);

my $gdbtn = $cmdframe->Checkbutton(
	-text => 'Use GD',
	-variable => \$gd)->grid(-column => 2, -row => 11, -columnspan => 2);
$gdbtn->configure(-state => 'disabled') unless $hasgd;

$cmdframe->StyledButton(
	-style => 'shiny',
	-shape => 'oval',
	-text => 'Render',
	-command => sub { renderButton(); })
	->grid(-column => 0, -row => 12, -columnspan => 2);

$cmdframe->StyledButton(
	-style => 'shiny',
	-shape => 'oval',
	-text => 'Rotate',
	-command => sub { rotateButton(); })
	->grid(-column => 2, -row => 12, -columnspan => 2);

my $started = 1;
renderButton();

MainLoop();

sub colorDialog {
	my $rgb;
	$color = $cmdframe->chooseColor(-title => 'Button color', -initialcolor => $color),
	$colorbtn->configure(-background => $color, -activebackground => $color),
	$rgb = $mw->rgb($color),
	$fullcolor = "$color(" . join(', ', @$rgb) . ')'
		if $started;
}

sub textColorDialog {
	my $rgb;
	$textcolor = $cmdframe->chooseColor(-title => 'Button color', -initialcolor => $textcolor),
	$textcolorbtn->configure(-background => $textcolor, -activebackground => $textcolor),
	$rgb = $mw->rgb($textcolor),
	$fulltextcolor = "$textcolor(" . join(', ', @$rgb) . ')'
		if $started;
}

sub setButtonFont {
#
#	open font dialog, collect data, and update
#	display
#
	$font = $mw->StyledFontDlg(-style => 'shiny', -shape => 'oval')->Show();
	$le->configure(-font => $font);
	$fontinfo = join('-', $font->actual(-family), $font->actual(-size), $font->actual(-weight), $font->actual(-slant));
}

sub renderButton {

#print $demobtn, "\n";

#	$demobtn->withdraw() if $demobtn;
#	$demobtn = undef;

	unless ($demobtns[0]) {
		$text = "$shape, $style";
		$demobtns[$_] = $canframe->StyledButton(
			-style => $style,
			-shape => $shape,
			-angle => $angle,
			-dispersion => $disperse,
			-background => $color,
			-text => $text,
			-font => $font)->pack(-side => 'left')
			foreach (0..1);
		return 1;
	}

	foreach (0..1) {
		$text ?
		$demobtns[$_]->configure(
			-style => $style,
			-shape => $shape,
			-angle => $angle,
			-dispersion => $disperse,
			-background => $color,
			-foreground => $textcolor,
			-text => $text,
			-font => $font) :
		$demobtns[$_]->configure(
			-style => $style,
			-shape => $shape,
			-angle => $angle,
			-dispersion => $disperse,
			-background => $color,
			-foreground => $textcolor,
			-text => '',
			-font => $font);
	}
}
