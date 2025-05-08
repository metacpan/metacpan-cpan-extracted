package Tk::ListBrowser::SelectXPM;

use strict;
use warnings;
use vars qw($VERSION);
use Convert::Color;

$VERSION =  0.05;

sub new {
	my ($class, $lb) = @_;
	my $self = {
		LB => $lb
	};
	bless($self, $class);
	return $self
}

sub offset {
	my ($self, $base, $factor, $div) = @_;
	$div = 2 unless defined $div;
	$base = $base * 255;
	my $new = ($base + $factor)/$div;
	$new = $new/255;
	return 1 if $new > 1;
	return $new
}

sub selectimage {
	my ($self, $x1, $y1, $x2, $y2) = @_;
	$x2 ++;
	$y2 ++;

	my $width = $x2 - $x1;
	my $height = $y2 - $y1;
	my $lb = $self->{LB};

	#create rgb
	my $sbg = $lb->cget('-selectbackground');
	$sbg =~ s/^#//;
	my $bg = Convert::Color->new("rgb8:$sbg");
	my ($red, $green, $blue) = $bg->rgb;
	
	#convert top rgb
	my $tred = $self->offset($red, 255, 1.75);
	my $tgreen = $self->offset($green, 255, 1.75);
	my $tblue =  $self->offset($blue, 255, 1.75);

	#convert bottom rgb
	my $bred = $self->offset($red, 0, 1.5);
	my $bgreen = $self->offset($green, 0, 1.5);
	my $bblue = $self->offset($blue, 0, 1.5);

	#create xpm color definitions
	my $t = Convert::Color->new("rgb:$tred,$tgreen,$tblue");
	my $b = Convert::Color->new("rgb:$bred,$bgreen,$bblue");
	my $top = '#' . $t->as_rgb8->hex;
	my $bottom = '#' . $b->as_rgb8->hex;
	my $fill = '#' . $bg->as_rgb8->hex;

	#create the image
	my $xpm = "/* XPM */
static char * select_draft_xpm[] = {
\"$width $height 3 1\",
\" 	c $top\",
\".	c $bottom\",
\"+	c $fill\",
";
	
	my $base = "\" ";
	my $end = ".\",\n";
	
	#create top line
	$xpm = "$xpm$base";
	for (1 .. $width - 2) { $xpm = "$xpm "}
	$xpm = "$xpm$end";
	#create body
	my $line = $base;
	for (1 .. $width - 2) { $line = "$line+"}
	$line = "$line$end";
	for (1 .. $height - 2) { $xpm = "$xpm$line" }
	#create bottom line
	$xpm = "$xpm$base";
	for (1 .. $width - 2) { $xpm = "$xpm."}
	$xpm = "$xpm$end";

#	my $pixmap = $lb->Pixmap(-data => $xpm);
	my $pixmap = $lb->Pixmap(-data => $xpm);
	my $c = $lb->Subwidget('Canvas');
	my $image = $c->createImage($x1, $y1,
		-image => $pixmap,
		-anchor => 'nw',
		-tags => ['sel'],
	);
#	print "image '$image'\n";
	return $image
}

1;