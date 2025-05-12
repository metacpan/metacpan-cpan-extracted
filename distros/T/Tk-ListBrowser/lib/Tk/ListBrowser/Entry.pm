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

$VERSION = 0.08;

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
	$self->opened(1);
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
		$self->drawAnchor
	} else {
		$self->deleteAnchor
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
	for ($self->canchor, $self->cguideH, $self->cguideV, $self->cindicator, $self->cselect) {
		$c->delete($_) if defined $_;
	}

	$self->canchor(undef);
	$self->cguideH(undef);
	$self->cguideV(undef);
	$self->cindicator(undef);
	$self->cselect(undef);
	$self->SUPER::clear;
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
	my $r = $self->cselect;
	return unless defined $r;
	
	my $c = $self->Subwidget('Canvas');
	$c->delete($r);
	$self->cselect(undef);

	my $t = $self->ctext;
	$c->itemconfigure($t,
		-fill => $self->cget('-foreground'),
	) if defined $t;

	my @columns = $self->columnList;
	for (@columns) {
		my $i = $self->itemGet($self->name, $_);
		$c->itemconfigure($i->ctext, 
			-fill => $self->cget('-foreground'),
		) if (defined $i) and (defined $i->ctext);
	}
}

sub drawAnchor {
	my ($self, $force) = @_;
	return unless $self->ismapped;
	
	my @coords = $self->region;
	$self->deleteAnchor;
	my $c = $self->Subwidget('Canvas');
	if ($self->listMode) {
		my ($cw) = $self->canvasSize;
		my $yscroll = $self->Subwidget('YScrollbar');
		$cw = $cw - $yscroll->width if $yscroll->ismapped;
		$coords[0] = 0;
		$coords[2] = $cw - 4;
	}
	my $a = $c->createRectangle(@coords,
		-fill => undef,
		-dash => [3, 2],
	);
	$self->canchor($a);
}

sub drawSelect {
	my $self = shift;
	return unless $self->ismapped;
	$self->deleteSelect;
	my $c = $self->Subwidget('Canvas');
	my $r = $self->crect;
	my $t = $self->ctext;
	my @columns = $self->columnList;
	my @coords = $self->region;
	if ($self->listMode) {
		my $lb = $self->listbrowser;
		my ($cw) = $self->canvasSize;
		my $yscroll = $self->Subwidget('YScrollbar');
		$cw = $cw - $yscroll->width if $yscroll->ismapped;
		$coords[0] = 0;
		$coords[2] = $cw - 4;
	}

	my $lb = $self->listbrowser;
	my $si = Tk::ListBrowser::SelectXPM->new($lb);
	my $a = $si->selectimage(@coords);
	$self->cselect($a);
	$c->raise($self->cimage, $a);
	$c->raise($t, $a);
	my @guides = $c->find('withtag', 'guides');
	for (@guides) {
		$c->raise($_, $a);
	}
	$c->raise($self->cindicator, $a);
	$c->raise($self->canchor, $a) if defined $self->canchor;
	$c->itemconfigure($t,
		-fill => $lb->cget('-selectforeground'),
	);
	for (@columns) {
		my $i = $self->itemGet($self->name, $_);
		if ((defined $i) and (defined $i->ctext)) {
			$c->raise($i->ctext, $a) if defined $i->ctext;
			$c->raise($i->cimage, $a) if defined $i->cimage;
			$c->itemconfigure($i->ctext, 
				-fill => $lb->cget('-selectforeground'),
			);
		}
	}
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

sub select {
	my ($self, $flag) = @_;
	$flag = 1 unless defined $flag;
	my $lb = $self->listbrowser;
	if ($flag) {
		return if $self->selected;
		$self->drawSelect
	} else {
		$self->deleteSelect
	}
	$self->{SELECTED} = $flag;
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

