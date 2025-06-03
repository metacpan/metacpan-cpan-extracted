package Tk::ListBrowser::List;

=head1 NAME

Tk::ListBrowser::List - List organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'list'
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
draw and navigate the list in a list organized manner.

No user serviceable parts inside.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION = 0.09;

use base qw(Tk::ListBrowser::Row);


sub draw {
	my ($self, $item, $x, $y, $column, $row) = @_;
	$self->SUPER::draw($item, $x, $y, $column, $row);
	my $entry = $item->name;
	my $cx;
	my $last;
	my @columns = $self->columnList;
	for (@columns) {
		my $col = $self->columnGet($_);
		if (defined $cx) {
			$cx = $cx + $last->cellWidth + 1;
		} else {
			$cx = $self->listWidth + 1 + $self->cget('-marginleft');
		}
		$last = $col;
		my $i = $self->itemGet($entry, $_);
		$i = $self->itemCreate($entry, $_) unless defined $i;
		$i->draw($cx, $y, $column, $row, $col->cget('-itemtype'));
	}
}

sub initColumns {
	my $self = shift;

	if ($self->headerAvailable) {
		$self->startXY($self->cget('-marginleft'), $self->cget('-margintop') + $self->cget('-headerheight'));
	} else {
		$self->startXY($self->SUPER::startXY);
	}

	my @pool = $self->listbrowser->getAll;
	my ($x, $y) = $self->startXY;
	my $rows = 0;
	for (@pool) {
		$rows ++ unless ($_->hidden) or (not $_->openedparent)
	}
	my $maxy = $y + ($rows * ($self->cellHeight + 1));

	my $ml = $self->cget('-marginleft');
	my $mr = $self->cget('-marginright');

	my $maxx = $self->listWidth + 1 + $ml;
	my @columns = $self->columnList;
	my $above;
	my $canvas = $self->Subwidget('Canvas');
	for (@columns) {
		my $c = $self->columnGet($_);
		my $dx = $maxx + $c->cellWidth;
		$c->region($maxx, $y, $dx, $maxy);
		$c->draw;
		$canvas->raise($c->crect, $above->crect) if defined $above;
		$above = $c;
		$maxx = $dx + 1;
	}

	$self->maxXY($maxx + $self->cget('-marginright'), $maxy + $self->cget('-marginbottom'));
}

sub listHeight {
	my $self = shift;
	$self->{LISTHEIGHT} = shift if @_;
	return $self->{LISTHEIGHT}
}

sub maxIndent {
	return 0
}

sub maxXY {
	my $self = shift;
	$self->{MAXXY} = [@_] if @_;
	my $m = $self->{MAXXY};
	return @$m
}

sub nextPosition {
	my ($self, $x, $y, $column, $row) = @_;
	my $cellheight = $self->cellHeight;
	$y = $y + $cellheight + 1;
	$row ++;
	return ($x, $y, $column, $row)
}

sub refresh {
	my $self = shift;

	#calculate sizes of side columns
	my @columns = $self->columnList;
	for (@columns) {
		my $col = $self->columnGet($_)->cellSize;
	}

	$self->SUPER::refresh;
	
	@columns = reverse @columns;
	my $c = $self->Subwidget('Canvas');
	while (@columns) {
		my $last = shift @columns;
		my $tag;
		my $prev = $columns[0];
		if (defined $prev) {
			my $col = $self->columnGet($prev);
			$tag = $col->crect;
		} else {
			$tag = 'main'
		}
		my $rlast = $self->columnGet($last)->crect;
		$c->lower($tag, $rlast);
	}
	$self->headerPlace;
}

sub scroll {
	return 'vertical'
}

sub startXY {
	my $self = shift;
	$self->{STARTXY} = [@_] if @_;
	my $sxy = $self->{STARTXY};
	return @$sxy
}

sub type {
	return 'list'
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=cut

1;
