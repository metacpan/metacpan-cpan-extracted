package Tk::ListBrowser::Entry;

=head1 NAME

Tk::ListBrowser::Item - List entry holding object.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
use Carp;
require Tk::ListBrowser::SelectXPM;
use Math::Round qw(round);

$VERSION = 0.15;

use base qw(Tk::ListBrowser::Item);

=head1 SYNOPSIS

 my $entry = $listbrowser->add($entryname, @options);

 my $entry = $listbrowser->get($entryname);

=head1 DESCRIPTION

Inherits L<Tk::ListBrowser::Item>.

This module creates an object that holds all information of every entry.

You can use the same options as it's ancestors. You can also use
the -hidden option, if you want an entry to remain hidden upon addition.


=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);

	$self->anchored(0);
	$self->drawrect(0) unless $self->configSet('-drawrect');
	$self->hidden(0) unless defined $self->hidden;
	$self->priority(0) unless defined $self->priority;
	$self->opened(1);
	$self->{ANCHOR} = 0;
	$self->{SELECTED} = 0;
	
	return $self
}

sub anchor {
	my ($self, $flag) = @_;
	return unless $self->ismapped;
	my $c = $self->Subwidget('Canvas');
	$flag = 1 unless defined $flag;
	$self->{ANCHOR} = $flag;
	if ($flag) {
		$self->refreshSingle($self->name) if $self->ismapped
	} else {
		$self->deleteAnchor if $self->ismapped
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
	for ($self->canchor, $self->cguideH, $self->cguideV, $self->cindicator) {
		$c->delete($_) if defined $_;
	}

	my @columns = $self->columnList;
	my $name = $self->name;
	for (@columns) {
		my $i = $self->itemGet($name, $_);
		$i->clear if defined $i;
	}

	$self->canchor(undef);
	$self->cguideH(undef);
	$self->cguideV(undef);
	$self->cindicator(undef);
	$self->SUPER::clear;
}

sub clickregion {
	my $self = shift;
	my @coords = $self->region;
	$coords[2] = 3000 if $self->listMode;
	return @coords;
}

sub ctext {
	my $self = shift;
	$self->{CTEXT} = shift if @_;
	return $self->{CTEXT}
}

sub deleteAnchor {
	my $self = shift;
	my $r = $self->canchor;
	return unless defined $r;
	
	my $c = $self->Subwidget('Canvas');
	$c->delete($r);
	$self->canchor(undef);
}

sub deleteSelect {
	my $self = shift;
	$self->deleteRect;
}

sub draw {
	my $self = shift;
	my ($x, $y) = @_;
	$self->SUPER::draw(@_);
	my $sel = $self->selected and $self->ismapped;
	$self->drawSelect if $sel;
}

sub drawAnchor {
	my ($self, $force) = @_;
	return unless $self->ismapped;
	
	my @coords = $self->elementCoords;
	$self->deleteAnchor;
	my $c = $self->Subwidget('Canvas');
	my $a = $c->createRectangle(@coords,
		-fill => undef,
		-dash => [3, 2],
		-tags => ['anchor'],
	);
	$self->canchor($a);
	$c->raise('guides', 'anchor');
}

sub drawSelect {
	my ($self) = @_;
	my $left = 1;
	my $right = 1;
	$self->deleteSelect;
	
	my $lb = $self->listbrowser;
	return unless $lb->ismapped;
	return unless $self->selected;
	my $c = $lb->Subwidget('Canvas');
	my $si = Tk::ListBrowser::SelectXPM->new($lb);

	my @coords = $self->elementCoords;
	return if $coords[0] >= $coords[2];
	return if $coords[1] >= $coords[3];

	my ($x, $y) = @coords;
	my $pixmap = $si->selectimage(@coords, $left, $right);
	my $image = $c->createImage($x, $y,
		-image => $pixmap,
		-anchor => 'nw',
		-tags => ['sel', 'rect', $self->name],
	);
	$self->crect($image);
	my @guides = $c->find('withtag', 'guides');
	$c->raise('guides', 'sel') if @guides;
	$c->raise('indicator', 'sel');
	$c->raise('indicator', 'guides') if @guides;
	$c->raise($self->cimage, $image);
	$c->raise($self->ctext, $image);
}

sub elementCoords {
	my $self = shift;
	my $lb = $self->listbrowser;
	my $c = $lb->Subwidget('Canvas');

	my @coords = $self->region;

	if ($self->listMode) {

		my ($width) = $lb->lastScrollRegion;
		my ($cw) = $self->canvasSize;

		my ($xv) = $c->xview;

		my $x1 = int($width * $xv);
		$coords[0] = $x1;
		my $x2 = $cw;
		if ($xv > 0) {
			$x2 = $x1 + $cw
		}
		$coords[2] = $x2;
	}
	return @coords
}

sub hasChildren {
	my $self = shift;
	my @c = $self->infoChildren($self->name);
	my $ch = @c;
	return $ch
}

sub hidden {
	my $self = shift;
	$self->{HIDDEN} = shift if @_;
	return $self->{HIDDEN}
}

sub inindicator {
	my ($self, $x, $y) = @_;
	my $i = $self->cindicator;
	return '' unless defined $i;
	my $c = $self->Subwidget('Canvas');
	my @coords = $c->coords($i);
	return 1 if ($coords[0] > $x) and ($coords[2] < $x) and ($coords[1] > $y) and ($coords[3] < $y);
	return ''
}

sub inregion {
	my ($self, $x, $y) = @_;
	my ($cx, $cy, $cdx, $cdy) = $self->clickregion;
	return '' unless $x >= $cx;
	return '' unless $x <= $cdx;
	return '' unless $y >= $cy;
	return '' unless $y <= $cdy;
	return 1
}

sub noshow {
	my $self = shift;
	return (($self->hidden) or (not $self->openedparent))
}

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

sub priority {
	my $self = shift;
	$self->{PRIORITY} = shift if @_;
	return $self->{PRIORITY}
}

sub select {
	my ($self, $flag) = @_;
	$flag = 1 unless defined $flag;
	return if $flag and $self->selected;
	return if (not $flag) and (not $self->selected);
	$self->{SELECTED} = $flag;
	$self->refreshSingle($self->name) if $self->ismapped;
}

sub selected { return $_[0]->{SELECTED} }


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

