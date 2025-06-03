package Tk::ListBrowser::Tree;

=head1 NAME

Tk::ListBrowser::Bar - Bar organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'tree'
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
present a hierarchical tree interface.

No user serviceable parts inside.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.09;

use Math::Round qw(round);

use base qw(Tk::ListBrowser::HList);

sub cellSize {
	my $self = shift;
	$self->SUPER::cellSize;
	$self->listWidth($self->listWidth + $self->cget('-indent'));
}

sub draw {
	my ($self, $item, $x, $y, $column, $row) = @_;
	my $indent = $self->cget('-indent');
	$x = $x + $indent;
	$self->SUPER::draw($item, $x, $y, $column, $row);
	my $entry = $item->name;
	if ($self->infoChildren($entry)) {
		my $ind;
		my $c = $self->Subwidget('Canvas');
		my @eregion = $item->region;
		my $ix = $eregion[0] - round($indent/2);
		my $iy = $eregion[1] + round(($eregion[3] - $eregion[1])/2);
		if ($item->opened) {
			$ind = $c->createImage($ix, $iy,
				-image => $self->cget('-indicatorminusimg'),
				-tags => ['main', 'indicator'],
			);
			$c->bind($ind, '<1>', sub { $self->entryClose($entry) });
		} else {
			$ind = $c->createImage($ix, $iy,
				-image => $self->cget('-indicatorplusimg'),
				-tags => ['main','indicator'],
			);
			$c->bind($ind, '<1>', sub { $self->entryOpen($entry) });
		}
		$item->cindicator($ind);
	}
}

sub entryClose {
	my ($self, $entry) = @_;
	$self->close($entry);
	$self->refreshPurge($self->index($entry), 1);
}

sub entryOpen {
	my ($self, $entry) = @_;
	$self->open($entry);
	$self->refreshPurge($self->index($entry), 1);
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=cut

1;
