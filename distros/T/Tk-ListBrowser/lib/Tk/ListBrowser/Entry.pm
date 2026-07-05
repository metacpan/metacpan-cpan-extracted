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

$VERSION = 0.12;

use base qw(Tk::ListBrowser::Item);

=head1 SYNOPSIS

 my $entry = $listbrowser->add($entryname, @options);

 my $entry = $listbrowser->get($entryname);

=head1 DESCRIPTION

Inherits L<Tk::ListBrowser::Item>.

This module creates an object that holds all information of every entry.
You will never need to create an entry object yourself.

You can use the same options as it's ancestors. You can also use
the -hidden option, if you want an entry to remain hidden upon addition.


=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);

	$self->anchored(0);
	$self->hidden(0) unless defined $self->hidden;
	$self->priority(0) unless defined $self->priority;
	$self->opened(1);
	$self->maxX(0);
	$self->maxY(0);
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
	for ($self->canchor, $self->cguideH, $self->cguideV, $self->cindicator, $self->cselectl, $self->cselectr) {
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
	$self->cselectl(undef);
	$self->cselectr(undef);
	$self->maxX(0);
	$self->maxY(0);
	$self->SUPER::clear;
}

sub cselectl {
	my $self = shift;
	$self->{CSELECTL} = shift if @_;
	return $self->{CSELECTL}
}

sub cselectr {
	my $self = shift;
	$self->{CSELECTR} = shift if @_;
	return $self->{CSELECTR}
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

sub draw {
	my $self = shift;
	$self->SUPER::draw(@_);
	$self->drawAnchor if $self->anchored
}

sub drawAnchor {
	my ($self, $force) = @_;
	return unless $self->ismapped;
	
	my @coords = $self->region;
	$self->deleteAnchor;
	my $c = $self->Subwidget('Canvas');
	if ($self->listMode) {
		my ($cw) = $self->canvasSize;
		$coords[0] = 0;
		$coords[2] = $cw;
	}
	my $a = $c->createRectangle(@coords,
		-fill => undef,
		-dash => [3, 2],
		-tags => ['anchor'],
	);
	$self->canchor($a);
}

sub drawSelect {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	my $lb = $self->listbrowser;
	my $si = Tk::ListBrowser::SelectXPM->new($lb);
	my @coords = $self->getRegion;
	unless ($self->listMode) {
		my $pixmap = $si->selectimage(@coords);
		my $image = $c->createImage($coords[0], $coords[1],
			-image => $pixmap,
			-anchor => 'nw',
			-tags => ['sel', $self->name],
		);
		$self->setRegion(@coords);
		$self->anchorRaise($image);
		$self->crect($image);
		return
	}

	#draw centerpiece
	$self->SUPER::drawSelect;


	#draw left piece
	my $lx = $coords[0];
	$lx++ if $lx eq 0;
	my $slpix = $si->selectimage(0, $coords[1], $lx, $coords[3], 1, 0);
	my $slimg = $c->createImage(0, $coords[1],
		-image => $slpix,
		-anchor => 'nw',
		-tags => ['sel', $self->name],
	);
	$self->anchorRaise($slimg);
	$self->cselectl($slimg);
	
	#draw right piece
	my @cols = $self->columnList;
	my $last = pop @cols;
	if (defined $last) {
		@coords = $self->itemGet($self->name, $last)->getRegion;
	}

	my ($cw) = $self->canvasSize;
	my $rx1 = $coords[2];
	my $rx2 = $cw;
	if ($rx1 > $cw) {
		$rx1 = $cw - 4;
		$rx2 = $cw;
	}
	$rx1 -- if $rx1 eq $rx2;
	$rx2 = $rx1 + 300 if $rx2 < $rx1; #a little hack to prevent segfault exit when unmapped.
	my $srpix = $si->selectimage($rx1, $coords[1], $rx2, $coords[3], 0, 1);
	my $srimg = $c->createImage($rx1, $coords[1],
		-image => $srpix,
		-anchor => 'nw',
		-tags => ['sel', $self->name],
	);

	my $r;
	if (defined $last) {
		$r = $self->itemGet($self->name, $last)->crect;
	} else {
		$r = $self->crect;
	}
	$c->raise($srimg, $r) if defined $r;
	$self->anchorRaise($srimg);
	$self->cselectr($srimg);
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

sub maxX {
	my $self = shift;
	$self->{MAXX} = shift if @_;
	return $self->{MAXX}
}

sub maxY {
	my $self = shift;
	$self->{MAXY} = shift if @_;
	return $self->{MAXY}
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

