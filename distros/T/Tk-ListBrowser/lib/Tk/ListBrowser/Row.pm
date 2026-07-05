package Tk::ListBrowser::Row;

=head1 NAME

Tk::ListBrowser::Row - Row organizer for Tk::ListBrowser.

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
$VERSION =  0.12;
use Carp;
use Math::Round;

sub new {
	my ($class, $lb) = @_;
	carp 'You did not specify a list browser' unless defined $lb;
	
	my $self = {
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

sub draw {
	my ($self, $item, $x, $y, $column, $row) = @_;
	$item->draw($x, $y, $column, $row, $self->cget('-itemtype'));
	$self->maxXYCalculate($item);
}

sub initColumns {
}

sub listbrowser { return $_[0]->{LISTBROWSER} }

sub maxXYCalculate {
	my ($self, $item, $entry) = @_;
	my $target = $item;
	$target = $entry if defined $entry;
	my $prev = $self->infoPrevVisible($target->name);
	my ($x1, $y1, $x2, $y2) = $item->region;
	if (defined $prev) {
		my $p = $target->get($prev);
		my $mx = $p->maxX;
		if ($x2 > $mx) {
			$target->maxX($x2)
		} else {
			$target->maxX($mx)
		}
		my $my = $p->maxY;
		if ($y2 > $my) {
			$target->maxY($y2)
		} else {
			$target->maxY($my)
		}
		
	} else {
		$item->maxX($x2);
		$item->maxY($y2);
	}
}

sub nextPosition {
	my ($self, $x, $y, $column, $row) = @_;
	my $cellheight = $self->cget('-cellheight');
	my $cellwidth = $self->cget('-cellwidth');
	my $newx = $x + ($cellwidth * 2);
	my ($cwidth, $cheight) = $self->canvasSize;
	if ($newx >= $cwidth) {
		$x = $self->cget('-marginleft');
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
	my @pool = $self->getPool;
	$self->clear;
	$self->cellSize;
	$self->initColumns;
	
	my ($x, $y) = $self->startXY;
	my $column = 0;
	my $row = 0;
	for (@pool) {
		my $item = $_;
		next if $item->noshow;
		$self->draw($item, $x, $y, $column, $row);

		($x, $y, $column, $row) = $self->nextPosition($x, $y, $column, $row);
	}
	$self->setScrollRegion
}

sub scroll {
	return 'vertical'
}

sub startXY {
	my $self = shift;
	$self->{STARTXY} = [@_] if @_;
	my $sxy = $self->{STARTXY};
	return ($self->cget('-marginleft'), $self->cget('-margintop')) unless defined $sxy;
	return @$sxy
}
#sub startXY {
#	my $self = shift;
#	return ($self->cget('-marginleft'), $self->cget('-margintop'))
#}

sub type {
	return 'row'
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=cut

1;
