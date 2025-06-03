package Tk::ListBrowser::HList;

=head1 NAME

Tk::ListBrowser::Bar - Bar organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'hlist'
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
present a hierarchical list interface.

No user serviceable parts inside.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.09;

use Math::Round qw(round);

use base qw(Tk::ListBrowser::List);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{STACK} = [];
	return $self;
}

sub cellSize {
	my $self = shift;

	my $cellheight = 0;
	my $cellwidth = 0;
	my $imageheight = 0;
	my $imagewidth = 0;
	my $textheight = 0;
	my $textwidth = 0;
	my $indent = 0;
	my @pool = $self->getAll;
	for (@pool) {
		my $entry = $_;

		#calculate max indent
		my $name = $entry->name;
		my $i = 0;
		my $sep = quotemeta($self->cget('-separator'));
		while ($name =~ /$sep/g) {	$i ++	}
		$indent = $i if $i > $indent;
		

		#calculate cell size
		my ($iw, $ih, $tw, $th) = $entry->minCellSize($self->cget('-itemtype'));
		$imageheight = $ih if $ih > $imageheight;
		$imagewidth = $iw if $iw > $imagewidth;
		$textheight = $th if $th > $textheight;
		$textwidth = $tw if $tw > $textwidth;
		for ($self->columnList) {
			my $col = $_;
			my $type = $self->columnCget($col, '-itemtype');
			my $item = $self->itemGet($entry->name, $col);
			if (defined $item) {
				my ($iw, $ih, $tw, $th) = $entry->minCellSize($type);
				$imageheight = $ih if $ih > $imageheight;
				$textheight = $th if $th > $textheight;
			}
			
		}
	}
	my $itemtype = $self->cget('-itemtype');
	if ($itemtype eq 'image') {
		$cellheight = $imageheight;
		$cellwidth = $imagewidth;
	} elsif ($itemtype eq 'text') {
		$cellheight = $textheight;
		$cellwidth = $textwidth;
	} else {
		my $textside = $self->cget('-textside');
		if (($textside eq 'top') or ($textside eq 'bottom')) {
			$cellheight = $imageheight + $textheight;
			$cellwidth = $imagewidth;
			$cellwidth = $textwidth if $textwidth > $cellwidth;
		} elsif (($textside eq 'left') or ($textside eq 'right')) {
			$cellheight = $imageheight;
			$cellheight = $textheight if $textheight > $cellheight;
			$cellwidth = $imagewidth + $textwidth;
		}
	}
	my $indentwidth = $indent * $self->cget('-indent');
	$self->cellHeight($cellheight);
	$self->cellImageHeight($imageheight);
	$self->cellImageWidth($imagewidth);
	$self->cellTextHeight($textheight);
	$self->cellTextWidth($textwidth);
	$self->cellWidth($cellwidth);
	$self->listWidth($cellwidth + $indentwidth - $self->cget('-indent'));
	$self->maxIndent($indentwidth);
	return ($cellwidth, $cellheight)
}

sub draw {
	my ($self, $item, $x, $y, $column, $row) = @_;

	#calculate indent
	my $indentsize = $self->cget('-indent');
	my $entry = $item->name;
	my $sep = quotemeta($self->cget('-separator'));
	my $count = 0;
	my $e = $entry;
	while ($e =~ s/^[^$sep]*$sep//) {
		$count ++
	}
#	($x) = $self->startXY;
	$x = $x + ($count * $indentsize);

	#draw entry
	$self->SUPER::draw($item, $x, $y, $column, $row);
	
	#draw guides
	my $parent = $self->infoParent($entry);
	if (defined $parent) {
		my $c = $self->Subwidget('Canvas');
		my @eregion = $item->region;
		my $p = $self->get($parent);
		my @pregion = $p->region;
		my $half = 8;

		#draw horizontal guide
		my $hx1 = $pregion[0] + round(($eregion[0] - $pregion[0])/2);
		my $hy1 = $eregion[1] + round(($eregion[3] - $eregion[1])/2);;
		my $hx2 = $eregion[0];
		my $hy2 = $hy1;
		my $guideh = $c->createLine($hx1, $hy1, $hx2, $hy2,
			-fill => $self->cget('-foreground'),
			-tags => ['main', 'guides'],
		);
		$item->cguideH($guideh);
		$c->lower($guideh);

		#draw vertical guide
		my $vx1 = $hx1;
		my $vy1 = $pregion[3];
		my $vx2 = $vx1;
		my $vy2 = $hy1;
		my $guidev = $c->createLine($vx1, $vy1, $vx2, $vy2,
			-fill => $self->cget('-foreground'),
			-tags => ['main', 'guides'],
		);
		$item->cguideV($guidev);
		$c->lower($guidev);
	}
}

sub getPool {
	my $self = shift;
	return $self->getAll;
}

sub maxIndent {
	my $self = shift;
	$self->{MAXINDENT} = shift if @_;
	return $self->{MAXINDENT}
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.


=cut

1;
