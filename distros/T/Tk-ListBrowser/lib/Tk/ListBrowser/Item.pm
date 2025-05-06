package Tk::ListBrowser::Item;

=head1 NAME

Tk::ListBrowser::Item - List entry holding object.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
use Carp;

$VERSION = 0.04;

use base qw(Tk::ListBrowser::BaseItem);

#used in formatText
my $dlmreg = qr/\.|\(|\)|\:|\!|\+|\,|\-|\<|\=|\>|\%|\&|\*|\"|\'|\/|\;|\?|\[|\]|\^|\{|\||\}|\~|\\|\$|\@|\#|\`|\s/;

=head1 SYNOPSIS

 my $item = $listbrowser->add($entryname, @options);

 my $item = $listbrowser->get($entryname);

=head1 DESCRIPTION

Inherits L<Tk::ListBrowser::BaseItem>.

This module creates an object that holds all information of every entry.
You will never need to create an item object yourself.

Besides the options in it's parent, you can use the I<-data>, I<-image>,
and I<-text> options.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);

	$self->anchored(0);
	$self->hidden(0) unless defined $self->hidden;
	$self->opened(1);
	$self->owner($self->listbrowser) unless defined $self->owner;
	$self->{ANCHOR} = 0;
	$self->{SELECTED} = 0;
	
	return $self
}

sub anchor {
	my ($self, $flag) = @_;
	my $c = $self->Subwidget('Canvas');
	$flag = 1 unless defined $flag;
	$self->{ANCHOR} = $flag;
	if ($flag) {
		my @coords;
		my @region = $self->region;
		if ($self->hierarchy) {
			my $lb = $self->listbrowser;
			my $sr = $lb->cget('-scrollregion');
			@coords = ($lb->cget('-marginleft'), $region[1], $sr->[2], $region[3]);
		} else {
			@coords = @region;
		}
		my $a = $c->createRectangle(@coords,
			-fill => undef,
			-dash => [3, 2],
		);
		$self->canchor($a);
	} else {
		my $a = $self->canchor;
		$c->delete($a) if defined $a;
	}
	return $self->{ANCHOR}
}

sub anchored { return $_[0]->{ANCHOR} }

sub canchor {
	my $self = shift;
	$self->{CANCHOR} = shift if @_;
	return $self->{CANCHOR}
}

sub cguideH {
	my $self = shift;
	$self->{CGUIDEH} = shift if @_;
	return $self->{CGUIDEH}
}

sub cguideV {
	my $self = shift;
	$self->{CGUIDEV} = shift if @_;
	return $self->{CGUIDEV}
}

sub cimage {
	my $self = shift;
	$self->{CIMAGE} = shift if @_;
	return $self->{CIMAGE}
}

sub cindicator {
	my $self = shift;
	$self->{CINDICATOR} = shift if @_;
	return $self->{CINDICATOR}
}

sub clear {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	for ($self->canchor, $self->cimage, $self->ctext, $self->cguideH, $self->cguideV, $self->cindicator, $self->cselect) {
		$c->delete($_) if defined $_;
	}
	$self->column(undef);
	$self->row(undef);

	$self->canchor(undef);
	$self->cguideH(undef);
	$self->cguideV(undef);
	$self->cimage(undef);
	$self->ctext(undef);
	$self->cindicator(undef);
	$self->cselect(undef);
	$self->SUPER::clear;
}

sub column {
	my $self = shift;
	$self->{COLUMN} = shift if @_;
	return $self->{COLUMN}
}

sub cselect {
	my $self = shift;
	$self->{CSELECT} = shift if @_;
	return $self->{CSELECT}
}

sub ctext {
	my $self = shift;
	$self->{CTEXT} = shift if @_;
	return $self->{CTEXT}
}

sub data {
	my $self = shift;
	$self->{DATA} = shift if @_;
	return $self->{DATA}
}

sub deleteImage {
	my $self = shift;
	my $i = $self->cimage;
	return unless defined $i;
	
	my $c = $self->Subwidget('Canvas');
	$c->delete($i);
	$self->cimage(undef);
}

sub deleteRect {
	my $self = shift;
	my $r = $self->crect;
	return unless defined $r;
	
	my $c = $self->Subwidget('Canvas');
	$c->delete($r);
	$self->crect(undef);
}

sub deleteText {
	my $self = shift;
	my $t = $self->ctext;
	return unless defined $t;
	
	my $c = $self->Subwidget('Canvas');
	$c->delete($t);
	$self->ctext(undef);
}

sub draw {
	my ($self, $x, $y, $column, $row, $type) = @_;

	my $image = $self->image;
	my $ih = 0;
	my $iw = 0;
	if (defined $image) {
		$ih = $image->height;
		$iw = $image->width;
	}

	my $text = $self->text;
	my $th = 0;
	my $tw = 0;
	if (defined $text) {
		my $textf = $self->textFormat($text);
		$th = $self->textHeight($textf);
		$tw = $self->textWidth($textf);
		$self->textFormatted($textf);
	}

	my $imageoffsetx = 0;
	my $imageoffsety = 0;
	my $textoffsetx = 0;
	my $textoffsety = 0;
	my @textcavity = (0, 0, 0, 0);

	my $owner = $self->owner;
	my $cellheight = $owner->cellHeight;
	my $cellwidth = $owner->cellWidth;
	my $imageheight = $owner->cellImageHeight;
	my $imagewidth = $owner->cellImageWidth;
	my $textheight = $owner->cellTextHeight;
	my $textwidth = $owner->cellTextWidth;

	my $itemtype = $owner->cget('-itemtype');
	if ($itemtype eq 'image') {
		$imageoffsetx = int(($cellwidth - $iw)/2);
		$imageoffsety = int(($cellheight - $ih)/2);
	} elsif ($itemtype eq 'text') {
		@textcavity = (0 ,0, $cellwidth, $cellheight)
	} else {
		my $textside = $owner->cget('-textside');
		if ($textside eq 'top') {
			@textcavity = (0, 0, $cellwidth, $textheight);
			$imageoffsety = $textheight + int(($imageheight - $ih)/2);
			$imageoffsetx = $imageoffsetx + int(($cellwidth - $iw)/2);
		} elsif ($textside eq 'bottom') {
			@textcavity = (0, $imageheight, $cellwidth, $cellheight);
			$imageoffsetx = $imageoffsetx + int(($cellwidth - $iw)/2);
			$imageoffsety = $imageoffsety + int(($imageheight - $ih)/2);
		} elsif ($textside eq 'left') {
			@textcavity = (0, 0, $textwidth, $cellheight);
			$imageoffsety = $imageoffsety + int(($cellheight - $ih)/2);
			$imageoffsetx = $textwidth;
		} elsif ($textside eq 'right') {
			@textcavity = ($imagewidth, 0, $cellwidth, $cellheight);
			$imageoffsety = $imageoffsety + int(($cellheight - $ih)/2);
			$imageoffsetx = int(($imagewidth - $iw)/2);
		}
	}

	my $centerx = $textcavity[0] + int(($textcavity[2] - $textcavity[0] - $tw)/2);
	my $centery = $textcavity[1] + int(($textcavity[3] - $textcavity[1] - $th)/2);

	my $lb = $self->listbrowser;
	my $padx = $lb->cget('-itempadx');
	my $pady = $lb->cget('-itempady');

	my $textanchor = $owner->cget('-textanchor');
	if ($textanchor eq '') {
		$textoffsetx = $centerx;
		$textoffsety = $centery;
	} elsif ($textanchor eq 's') {
		$textoffsetx = $centerx;
		$textoffsety = $textcavity[3] - $th - $pady;
	} elsif ($textanchor eq 'e') {
		$textoffsetx = $textcavity[2] - $tw - $padx;
		$textoffsety = $centery;
	} elsif ($textanchor eq 'n') {
		$textoffsetx = $centerx;
		$textoffsety = $textcavity[1] + $pady;
	} elsif ($textanchor eq 'w') {
		$textoffsetx = $textcavity[0] + $padx;
		$textoffsety = $centery;
	} elsif ($textanchor eq 'se') {
		$textoffsetx = $textcavity[2] - $tw - $padx;
		$textoffsety = $textcavity[3] - $th - $pady;
	} elsif ($textanchor eq 'sw') {
		$textoffsetx = $textcavity[0] + $padx;
		$textoffsety = $textcavity[3] - $th - $pady;
	} elsif ($textanchor eq 'ne') {
		$textoffsetx = $textcavity[2] - $tw - $padx;
		$textoffsety = $textcavity[1] + $pady;
	} elsif ($textanchor eq 'nw') {
		$textoffsetx = $textcavity[0] + $padx;
		$textoffsety = $textcavity[1] + $pady;
	}
	$self->imageX($x + $imageoffsetx);
	$self->imageY($y + $imageoffsety);
	$self->rectX($x);
	$self->rectY($y);
	$self->textX($x + $textoffsetx);
	$self->textY($y + $textoffsety);

	$self->drawRect;
	$self->drawImage;
	$self->drawText;

	$self->column($column);
	$self->row($row);
	$self->ismapped(1);
}

sub drawImage {
	my $self = shift;
	my $image = $self->image;
	return unless defined $image;
	return unless $self->itemtype =~ /image/;
	$self->deleteImage;

	my $itag;
	my $c = $self->Subwidget('Canvas');
	$itag = $c->createImage($self->imageX, $self->imageY,
		-image => $image,
		-anchor => 'nw',
		-tags => $self->tags,
	);

	$self->cimage($itag);
}

sub drawRect {
	my $self = shift;
	$self->deleteRect;
	my $owner = $self->owner;
	my $c = $self->Subwidget('Canvas');

	my $x = $self->rectX;
	my $y = $self->rectY;
	my $dx = $x + $owner->cellWidth;
	my $dy = $y + $owner->cellHeight;
	my $rtag = $c->createRectangle($x, $y, $dx, $dy,
		-fill => $self->background,
		-outline => $self->background,
		-tags => $self->tags,
	);

	if (($owner eq $self->listbrowser) and ($self->columnCapable)) {
		my @columns = $self->columnList;
		for (@columns) {
			my $col = $self->columnGet($_);
			$dx = $dx + $col->cellWidth + 1;
		}
	}
	$self->region($x, $y, $dx, $dy);
	$self->crect($rtag);

	$c->raise($self->cimage) if defined $self->cimage;
	$c->raise($self->ctext) if defined $self->ctext;
}

sub drawText {
	my $self = shift;
	my $text = $self->textFormatted;
	return unless defined $text;
	return unless $self->itemtype =~ /text/;
	$self->deleteText;
	my $x = $self->textX;
	my $y = $self->textY;

	my $ttag;
	my $c = $self->Subwidget('Canvas');
	$ttag = $c->createText($x, $y,
		-fill => $self->foreground,
		-text => $text,
		-justify => $self->textjustify,
		-anchor => 'nw',
		-font => $self->font,
		-tags => $self->tags,
	) if defined $text;

	$self->ctext($ttag);

}

sub hidden {
	my $self = shift;
	$self->{HIDDEN} = shift if @_;
	return $self->{HIDDEN}
}

sub image {
	my $self = shift;
	if (@_) {
		$self->{IMAGE} = shift;
		$self->drawImage if defined $self->crect;
	}
	return $self->{IMAGE}
}

sub imageX {
	my $self = shift;
	$self->{IMAGEX} = shift if @_;
	return $self->{IMAGEX}
}

sub imageY {
	my $self = shift;
	$self->{IMAGEY} = shift if @_;
	return $self->{IMAGEY}
}

sub isentry {
	my $self = shift;
	return $self->owner eq $self->listbrowser;
}

sub inregion {
	my ($self, $x, $y) = @_;
	my ($cx, $cy, $cdx, $cdy) = $self->region;
	return '' unless $x >= $cx;
	return '' unless $x <= $cdx;
	return '' unless $y >= $cy;
	return '' unless $y <= $cdy;
	return 1
}

sub minCellSize {
	my ($self, $itemtype) = @_;
	$itemtype = 'imagetext' unless defined $itemtype;
	my $cellheight = 0;
	my $cellwidth = 0;;
	my $imageheight = 0;
	my $imagewidth = 0;
	my $textheight = 0;
	my $textwidth = 0;
	my $image = $self->image;
	if (defined $image) {
		$imageheight = $image->height;
		$imagewidth = $image->width;
	}
	my $text = $self->text;
	if (defined $text) {
		$text = $self->textFormat($text);
		$textheight = $self->textHeight($text);
		$textwidth = $self->textWidth($text);
	}
	my $pad = 6;
#	$pad = 6 if $itemtype ne 'imagetext';
	$imageheight = $imageheight + $pad;
	$imagewidth = $imagewidth + $pad;
	$textheight = $textheight + $pad;
	$textwidth = $textwidth + $pad;
	return ($imagewidth, $imageheight, $textwidth, $textheight)
}

sub name { return $_[0]->{NAME} }

sub opened {
	my $self = shift;
	$self->{OPENED} = shift if @_;
	return $self->{OPENED}
}

sub openedparent {
	my $self = shift;
	my $name = $self->name;
	my $p = $self->infoParent($name);
	my $r = '';
	if (defined $p) {
		my $parent = $self->get($p);
		if (($parent->openedparent) and ($parent->opened)) {
			$r = 1
		}
	} else {
		#is root always open
		$r = 1
	}
	return $r
}

sub rectX {
	my $self = shift;
	$self->{RECTX} = shift if @_;
	return $self->{RECTX}
}

sub rectY {
	my $self = shift;
	$self->{RECTY} = shift if @_;
	return $self->{RECTY}
}

sub region {
	my $self = shift;
	$self->{REGION} = [@_] if @_;
	my $r = $self->{REGION};
	return @$r;
}

sub row {
	my $self = shift;
	$self->{ROW} = shift if @_;
	return $self->{ROW}
}

sub select {
	my ($self, $flag) = @_;
	$flag = 1 unless defined $flag;
	my $lb = $self->listbrowser;
	my $c = $self->Subwidget('Canvas');
	my $r = $self->crect;
	my $t = $self->ctext;
	my @columns = $self->columnList;
	if ($flag) {
		return if $self->selected;
		my @coords;
		my @region = $self->region;
		if ($self->hierarchy) {
			my $lb = $self->listbrowser;
			my $sr = $lb->cget('-scrollregion');
			@coords = ($lb->cget('-marginleft'), $region[1], $sr->[2], $region[3]);
		} else {
			@coords = @region;
		}
		my $a = $c->createRectangle(@coords,
			-fill => $lb->cget('-selectbackground'),
			-outline => $lb->cget('-selectbackground'),
			-tags => ['sel'],
		);
		$self->cselect($a);
		$c->raise($self->cimage, $a);
		$c->raise($t, $a);
		$c->raise($self->cindicator, $a);
		$c->raise($self->cguideH, $a);
		$c->raise($self->cguideV, $a);
		my $next = $self->infoNext($self->name);
		if (defined $next) {
			my $n = $self->get($next);
			$c->raise($n->cguideV, $a);
		}
		$c->itemconfigure($t,
			-fill => $lb->cget('-selectforeground'),
		);
		for (@columns) {
			my $i = $self->itemGet($self->name, $_);
			if ((defined $i) and (defined $i->ctext)) {
				$c->raise($i->ctext, $a) if defined $i->ctext;
				$c->itemconfigure($i->ctext, 
					-fill => $lb->cget('-selectforeground'),
				);
			}
		}
	} else {
		my $a = $self->cselect;
		$c->delete($a);
		$self->cselect(undef);
		$c->itemconfigure($t, 
			-fill => $self->cget('-foreground'),
		);
		for (@columns) {
			my $i = $self->itemGet($self->name, $_);
			$c->itemconfigure($i->ctext, 
				-fill => $self->cget('-foreground'),
			) if (defined $i) and (defined $i->ctext);
		}
	}
	$self->{SELECTED} = $flag;
}

sub selected { return $_[0]->{SELECTED} }

sub tags {
	my $self = shift;
	my $owner = $self->owner;
	my @tags;
	if ($owner eq $self->listbrowser) {
		push @tags, 'main'
	} else {
		push @tags, $owner->crect;
	}
	return \@tags;
}

sub text {
	my $self = shift;
	if (@_) {
		my $t = shift;
		$self->{TEXT} = $t;
		if ((defined $t) and (defined $self->crect)) {
			$self->textFormatted($self->textFormat($t));
			$self->drawText
		}
	}
	return $self->{TEXT}
}

sub textFormatted {
	my $self = shift;
	$self->{TEXTFORMATTED} = shift if @_;
	return $self->{TEXTFORMATTED}
}


=item B<textFormat>I<($text)>

Formats, basically wraps, I<$text> taking the option I<-wraplength> into account.
I<$text> can be a multi line string.

=cut

sub textFormat {
	my ($self, $text) = @_;
	my $wraplength = $self->wraplength;
	my $font = $self->font;
	return $text if $wraplength eq 0;
	my @lines = split (/\n/, $text);
	my @out;
	for (@lines) {
		my $line = $_;
		my $length = $self->fontMeasure($font, $line);
		if ($length > $wraplength) {
			my $res = $length / length($line);
			my $oklength = int($wraplength/$res);
			while (length($line) > $oklength) {
				my $t = substr($line, 0, $oklength, '');
				if ($t =~ s/([$dlmreg])([^$dlmreg]+$)//) {
					$line = "$2$line";
					$t = "$t$1";
				}
				push @out, $t;
			}
			push @out, $line;
		} else {
			push @out, $line;
		}
	}
	my $result = '';
	while (@out) {
		$result = $result . shift @out;
		$result = "$result\n" if @out
	}
	return $result
}

=item B<textHeight>I<($text)>

Returns the display height of I<$text> in pixels.
I<$text> can be a multi line string.

=cut

sub textHeight {
	my ($self, $text) = @_;
	return 0 if $text eq '';
	my $height = 1;
	while ($text =~ /\n/g) { $height ++ }
	my $font = $self->cget('-font');
	return ($height * $self->fontMetrics($font, '-linespace')) #+ $self->fontMetrics($font, '-descent');;
}

=item B<textWidth>I<($text)>

Returns the display width of I<$text> in pixels.
I<$text> can be a multi line string.

=cut

sub textWidth {
	my ($self, $text) = @_;
	my $font = $self->font;
	my $width = 0;
	my @lines = split("\n", $text);
	for (@lines) {
		my $w = $self->fontMeasure($font, $_);
		$width = $w if $w > $width;
	}
	return $width
}

sub textX {
	my $self = shift;
	$self->{TEXTX} = shift if @_;
	return $self->{TEXTX}
}

sub textY {
	my $self = shift;
	$self->{TEXTY} = shift if @_;
	return $self->{TEXTY}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser::BaseItem>

=back

