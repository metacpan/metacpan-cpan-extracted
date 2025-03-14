package Tk::ListBrowser::Row;

=head1 NAME

Tk::ListBrowser - Tk::ListBrowser::Row - Row organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'row'
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
draw and navigate the list in a row organized manner.

No user serviceable parts inside.

=cut

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
$VERSION =  0.01;
use Carp;
use Math::Round;

sub new {
	my ($class, $lb) = @_;
	carp 'You did not specify a list browser' unless defined $lb;
	
	my $self = {
		CELLHEIGHT => 0,
		CELLWIDTH => 0,
		IMAGEHEIGHT => 0,
		IMAGEWIDTH => 0,
		TEXTHEIGHT => 0,
		TEXTWIDTH => 0,
		LISTBROWSER => $lb,
	};
	bless $self, $class;
	return $self
}

sub AUTOLOAD {
	my $self = shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD =~ s/^.*:://;
	return $self->{LISTBROWSER}->$AUTOLOAD(@_);
}

sub cellHeight {
	my $self = shift;
	$self->{CELLHEIGHT} = shift if @_;
	return $self->{CELLHEIGHT}
}

sub cellImageHeight {
	my $self = shift;
	$self->{IMAGEHEIGHT} = shift if @_;
	return $self->{IMAGEHEIGHT}
}

sub cellImageWidth {
	my $self = shift;
	$self->{IMAGEWIDTH} = shift if @_;
	return $self->{IMAGEWIDTH}
}

sub cellSize {
	my $self = shift;
	my $pool = $self->pool;
	my $imageheight = 0;
	my $imagewidth = 0;
	my $textwidth = 0;
	my $textheight = $self->fontMetrics($self->cget('-font'), '-descent');
0;
	for (@$pool) {
		my $image = $_->image;
		if (defined $image) {
			my $ih = $image->height;
			$imageheight = $ih if $ih > $imageheight;
			my $iw = $image->width;
			$imagewidth = $iw if $iw > $imagewidth;
		}
		my $text = $_->text;
		if (defined $text) {
			$text = $self->textFormat($_->text);
			my $th = $self->textHeight($text);
			$textheight = $th if $th > $textheight;
			my $tw = $self->textWidth($text);
			$textwidth = $tw if $tw > $textwidth;
		}
	}
	my $itemtype = $self->cget('-itemtype');
	my $pad = 6;
	$pad = 4 if $itemtype ne 'imagetext';
	$imageheight = $imageheight + $pad;
	$imagewidth = $imagewidth + $pad;
	$textheight = $textheight + $pad;
	$textwidth = $textwidth + $pad;
	my $cellheight;
	my $cellwidth;
	my $textside = $self->cget('-textside');
	if ($itemtype eq 'image') {
		$cellheight = $imageheight + $pad;
		$cellwidth = $imagewidth + $pad;
	} elsif ($itemtype eq 'text') {
		$cellheight = $textheight + $pad;
		$cellwidth = $textwidth + $pad;
	} else {
		if (($textside eq 'top') or ($textside eq 'bottom')) {
			$cellheight = $imageheight + $textheight + $pad;
			$cellwidth = $imagewidth;
			$cellwidth = $textwidth if $textwidth > $cellwidth;
			$cellwidth = $cellwidth + $pad - 2;
		} elsif (($textside eq 'left') or ($textside eq 'right')) {
			$cellheight = $imageheight;
			$cellheight = $textheight if $textheight > $cellheight;
			$cellheight = $cellheight + $pad - 2;
			$cellwidth = $imagewidth + $textwidth + $pad;
		}
	}
	$self->cellHeight($cellheight);
	$self->cellImageHeight($imageheight);
	$self->cellImageWidth($imagewidth);
	$self->cellTextHeight($textheight);
	$self->cellTextWidth($textwidth);
	$self->cellWidth($cellwidth);
	return ($cellwidth, $cellheight)
}

sub cellTextHeight {
	my $self = shift;
	$self->{TEXTHEIGHT} = shift if @_;
	return $self->{TEXTHEIGHT}
}

sub cellTextWidth {
	my $self = shift;
	$self->{TEXTWIDTH} = shift if @_;
	return $self->{TEXTWIDTH}
}


sub cellWidth {
	my $self = shift;
	$self->{CELLWIDTH} = shift if @_;
	return $self->{CELLWIDTH}
}

sub KeyArrowNavig {
	my ($self, $dcol, $drow) = @_;
	return undef if $self->anchorInitialize;
	my $pool = $self->pool;
	my $i = $self->anchorGet;
	if ($drow eq 0) { #horizontal move
		my $index = $self->index($i->name);
		$index = $index + $dcol;
		return $self->getIndex($index);
	} else { #vertical move
		my $col = $i->column;
		my $row = $i->row;
		my $max = $self->lastRowInColumn($col);
		if ($drow > 0) { #one row down
			if ($row eq $max) {
				$col ++;
				$row = -1
			}
		} else { #going up
			if ($row eq 0) {
				$col --;
				$row = $self->lastRowInColumn($col) + 1;
			}
		}
		my $nrow = $row + $drow;
		my $index = $self->indexColumnRow($col, $nrow);
		return $self->getIndex($index);
	}
}

sub nextPosition {
	my ($self, $x, $y, $column, $row) = @_;
	my $cellheight = $self->cellHeight;
	my $cellwidth = $self->cellWidth;
	my $newx = $x + ($cellwidth * 2);
	my ($cwidth, $cheight) = $self->canvasSize;
	if ($newx >= $cwidth) {
		$x = 0;
		$y = $y + $cellheight + 1;
		$column = 0;
		$row ++;
	} else {
		$x = $x + $cellwidth + 1;
		$column ++;
	}
	return ($x, $y, $column, $row)
}

sub refresh {
	my $self = shift;
	my $pool = $self->pool;
	$self->clear;
	my ($cellwidth, $cellheight) = $self->cellSize;
	my $x = 0;
	my $y = 0;
	my $ioffsetx = 0;
	my $maxx = 0;
	my $maxy = 0;
	my $column = 0;
	my $row = 0;
	my $fontdescent = $self->fontMetrics($self->cget('-font'), '-descent');
	for (@$pool) {
		my $item = $_;
		next if $item->hidden;

		my $image = $item->image;
		my $ih = 0;
		my $iw = 0;
		if (defined $image) {
			$ih = $image->height;
			$iw = $image->width;
		}

		my $text = $item->text;
		my $th = 0;
		my $tw = 0;
		if (defined $text) {
			$text = $self->textFormat($item->text);
			$th = $self->textHeight($text);
			$tw = $self->textWidth($text);
		}
		
		my $imageoffsetx = 0;
		my $imageoffsety = 0;
		my $textoffsetx = 0;
		my $textoffsety = 0;
		my @textcavity = (0, 0, 0, 0);

		my $imageheight = $self->cellImageHeight;
		my $imagewidth = $self->cellImageWidth;
		my $textheight = $self->cellTextHeight;
		my $textwidth = $self->cellTextWidth;

		my $itemtype = $self->cget('-itemtype');
		if ($itemtype eq 'image') {
			$imageoffsetx = int(($cellwidth - $iw)/2);
			$imageoffsety = int(($cellheight - $ih)/2);
		} elsif ($itemtype eq 'text') {
			@textcavity = (0 ,0, $cellwidth, $cellheight)
		} else {
			my $imageheight = $self->cellImageHeight;
			my $imagewidth = $self->cellImageWidth;
			my $textheight = $self->cellTextHeight;
			my $textwidth = $self->cellTextWidth;
			my $textside = $self->cget('-textside');
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
			}
		}

		my $centerx = $textcavity[0] + int(($textcavity[2] - $textcavity[0] - $tw)/2);
		my $centery = $textcavity[1] + int(($textcavity[3] - $textcavity[1] - $th)/2);

		my $textanchor = $self->cget('-textanchor');
		if ($textanchor eq '') {
			$textoffsetx = $centerx;
			$textoffsety = $centery;
		} elsif ($textanchor eq 's') {
			$textoffsetx = $centerx;
			$textoffsety = $textcavity[3] - $th;
		} elsif ($textanchor eq 'e') {
			$textoffsetx = $textcavity[2] - $tw;
			$textoffsety = $centery;
		} elsif ($textanchor eq 'n') {
			$textoffsetx = $centerx;
			$textoffsety = $textcavity[1];
		} elsif ($textanchor eq 'w') {
			$textoffsetx = $textcavity[0];
			$textoffsety = $centery;
		} elsif ($textanchor eq 'se') {
			$textoffsetx = $textcavity[2] - $tw;
			$textoffsety = $textcavity[3] - $th;
		} elsif ($textanchor eq 'sw') {
			$textoffsetx = $textcavity[0];
			$textoffsety = $textcavity[3] - $th;
		} elsif ($textanchor eq 'ne') {
			$textoffsetx = $textcavity[2] - $tw;
			$textoffsety = $textcavity[1];
		} elsif ($textanchor eq 'nw') {
			$textoffsetx = $textcavity[0];
			$textoffsety = $textcavity[1];
		}

		if ($itemtype =~ /image/) {
			my $itag;
			$itag = $self->createImage($x + $imageoffsetx, $y + $imageoffsety, 
				-image => $image, 
				-anchor => 'nw',
			) if defined $image;
			$item->cimage($itag);
		}
		if ($itemtype =~ /text/) {
			my $ttag;
			$ttag = $self->createText($x + $textoffsetx, $y + $textoffsety, 
				-text => $text,
				-justify => $self->cget('-textjustify'),
				-anchor => 'nw',
				-font => $self->cget(-font),
			) if defined $text;
			$item->ctext($ttag);
		}
		my $dx = $x + $cellwidth;
		my $dy = $y + $cellheight;
		my $rtag = $self->createRectangle($x, $y, $dx, $dy,
			-fill => undef,
			-outline => undef,
		);
		$item->crect($rtag);
		$item->region($x, $y, $dx, $dy);
		$item->column($column);
		$item->row($row);
		my ($cwidth, $cheight) = $self->canvasSize;
		($x, $y, $column, $row) = $self->nextPosition($x, $y, $column, $row);
		$maxx = $x if $x > $maxx;
		$maxy = $y if $y > $maxy;
	}
	$self->configure(-scrollregion => [0, 0, $maxx + $cellwidth + 2, $maxy + $cellheight + 2]);
}

sub scroll {
	return 'vertical'
}

sub type {
	return 'row'
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser>

=item L<Tk::ListBrowser::Bar>

=item L<Tk::ListBrowser::Column>

=item L<Tk::ListBrowser::Item>

=item L<Tk::ListBrowser::List>

=back

=cut

1;
