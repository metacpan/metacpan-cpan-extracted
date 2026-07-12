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
$VERSION =  0.14;

use Math::Round qw(round);

use base qw(Tk::ListBrowser::List);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{STACK} = [];
	return $self;
}

sub calculateDepth {
	my ($self, $item) = @_;
	my $name = $item->name;
	my $i = 0;
	my $sep = quotemeta($self->cget('-separator'));
	while ($name =~ /$sep/g) {	$i ++	}
	return $i
}

sub draw {
	my ($self, $item, $x, $y, $column, $row) = @_;

	#calculate indent
	my $indentsize = $self->cget('-indent');
	$x = $self->cget('-marginleft');
	$x = $x + $indentsize if ref $self eq 'Tk::ListBrowser::Tree';
	my $entry = $item->name;
	my $sep = quotemeta($self->cget('-separator'));
	my $depth = $self->calculateDepth($item);
	$x = $x + ($depth * $indentsize);

	#draw entry
	$self->SUPER::draw($item, $x, $y, $column, $row);
	
	#draw guides
	my $parent = $self->infoParent($entry);
	if (defined $parent) {
		my $c = $self->Subwidget('Canvas');
		my @eregion = $item->getRegion;
		my $p = $self->get($parent);
		my @pregion = $p->region;
		my $half = 8;

		#draw horizontal guide
		my $hx1 = $x - round($indentsize/2);
		my $hy1 = $y + round($self->cget('-cellheight')/2);
		my $hx2 = $x;
		my $hy2 = $hy1;
		my $guideh = $c->createLine($hx1, $hy1, $hx2, $hy2,
			-fill => $self->cget('-foreground'),
			-tags => ['main', 'guides'],
		);
		$item->cguideH($guideh);
#		$c->lower($guideh);

		#draw vertical guide
		my $vx1 = $hx1;
		my $vy1 = $p->rectY + $self->cget('-cellheight');
		my $vx2 = $vx1;
		my $vy2 = $hy1;
		my $guidev = $c->createLine($vx1, $vy1, $vx2, $vy2,
			-fill => $self->cget('-foreground'),
			-tags => ['main', 'guides'],
		);
		$item->cguideV($guidev);

		my @ind = $c->find('withtag', 'indicator');
		for (@ind) {
			$c->raise($_, $guideh);
			$c->raise($_, $guidev);
		}
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
