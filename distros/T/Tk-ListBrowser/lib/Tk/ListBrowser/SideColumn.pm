package Tk::ListBrowser::SideColumn;

=head1 NAME

Tk::ListBrowser::SideColumn - Side columns for Tk::ListBrowser.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
use Carp;
$VERSION =  0.12;

use base qw(Tk::ListBrowser::BaseItem);

=head1 SYNOPSIS

 my $column = $listbrowser->columnAdd($columnyname, @options);

=head1 DESCRIPTION

Inherits L<Tk::ListBrowser::BaseItem>.

This module creates an object that holds all information of every entry.
You will never need to create an side column object yourself.

Besides the options in it's parent, you can use the I<-sortcase>,
I<-sortfield>,and I<-sortnumerical> options.

Furthermore you can set the I<-cellwidth>, I<-imagecellwidth> and I<-textcellwidth> options.
The height options are not available since the height is determined by the main entry.

There is also the I<-drawrect> option. By default it is set to 0. If you set it the column will
draw a background rectangle in the background color. Do not use this in tree mode. It will clutter
your display when activating indicators.

=cut

sub new {
	my $class = shift;
	

	my $self = $class->SUPER::new(@_);

	$self->filterfield('text') unless defined $self->filterfield;
	$self->itemtype('text') unless defined $self->itemtype;
	$self->drawrect(0) unless defined $self->drawrect;
	$self->sortcase('') unless defined $self->sortcase;
	$self->sortfield('text') unless defined $self->sortfield;
	$self->sortnumerical('') unless defined $self->sortnumerical;
	$self->cellimagewidth(0);
	$self->celltextwidth(0);
	$self->cellwidth(100);
	$self->{VALUES} = {};

	return $self
}

sub cellimagewidth {
	my $self = shift;
	$self->{IMAGEWIDTH} = shift if @_;
	return $self->{IMAGEWIDTH}
}

sub celltextwidth {
	my $self = shift;
	$self->{TEXTWIDTH} = shift if @_;
	return $self->{TEXTWIDTH}
}

sub cellSize {
	my $self = shift;

	my $cellwidth = 0;
	my $imagewidth = 0;
	my $textwidth = 0;

	my $values = $self->{VALUES};
	for (keys %$values) {
		my $item = $values->{$_};
		my ($cw, $ch, $iw, $ih, $tw, $th) = $item->requestedSize;
		$imagewidth = $iw if $iw > $imagewidth;
		$textwidth = $tw if $tw > $textwidth;
		my $itemtype = $self->cget('-itemtype');
		if ($itemtype eq 'image') {
			$cellwidth = $imagewidth;
		} elsif ($itemtype eq 'text') {
			$cellwidth = $textwidth;
		} else {
			my $textside = $self->cget('-textside');
			if (($textside eq 'top') or ($textside eq 'bottom')) {
				$cellwidth = $imagewidth;
				$cellwidth = $textwidth if $textwidth > $cellwidth;
				$cellwidth = $cellwidth;
			} elsif (($textside eq 'left') or ($textside eq 'right')) {
				$cellwidth = $imagewidth + $textwidth;
			}
		}
	}
	$self->cellwidth($cellwidth);
	$self->cellimagewidth($imagewidth);
	$self->celltextwidth($textwidth);
	return $cellwidth;
}

sub cellwidth {
	my $self = shift;
	$self->{CELLWIDTH} = shift if @_;
	my $fw = $self->forceWidth;
	return $fw if defined $fw;
	return $self->{CELLWIDTH}
}

sub clear {
	my $self = shift;
	$self->SUPER::clear;
	my @items = $self->itemList;
	for (@items) { $self->itemGet($_)->clear }
}

sub draw {
	my $self = shift;
	return unless $self->drawrect;
	my $c = $self->Subwidget('Canvas');
	my @region = $self->region;
	my $rtag = $c->createRectangle($self->region,
		-fill => $self->background,
		-outline => undef,
		-tags => [$self->name],
	);
#	$self->anchorRaise($rtag);
	$c->lower($rtag);
	$self->crect($rtag);
}

sub drawrect {
	my $self = shift;
	$self->{DRAWRECT} = shift if @_;
	return $self->{DRAWRECT}
}

sub filterfield {
	my $self = shift;
	$self->{FILTERFIELD} = shift if @_;
	return $self->{FILTERFIELD}
}

sub forceWidth {
	my $self = shift;
	$self->{FORCEWIDTH} = shift if @_;
	return $self->{FORCEWIDTH}
}

sub header {
	my $self = shift;
	$self->{HEADER} = shift if @_;
	return $self->{HEADER}
}

sub itemAdd {
	my ($self, $entry, $item) = @_;
	my $vh = $self->{VALUES};
	$vh->{$entry} = $item;
}

sub itemExists {
	my ($self, $entry) = @_;
	my $vh = $self->{VALUES};
	return exists $vh->{$entry};
}

sub itemGet {
	my ($self, $entry) = @_;
	my $vh = $self->{VALUES};
	return $vh->{$entry};
}

sub itemList {
	my ($self, $entry) = @_;
	my $vh = $self->{VALUES};
	return keys %$vh;
}

sub itemRemove {
	my ($self, $entry) = @_;
	my $vh = $self->{VALUES};
	my $i = $vh->{$entry};
	return unless defined $i;
	$i->clear;
	delete $vh->{$entry};
}

sub sortcase{
	my $self = shift;
	$self->{SORTCASE} = shift if @_;
	return $self->{SORTCASE}
}

sub sortfield{
	my $self = shift;
	$self->{SORTFIELD} = shift if @_;
	return $self->{SORTFIELD}
}

sub sortnumerical{
	my $self = shift;
	$self->{SORTNUMERICAL} = shift if @_;
	return $self->{SORTNUMERICAL}
}

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

=cut

