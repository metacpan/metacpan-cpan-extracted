package Tk::ListBrowser::Item;

=head1 NAME

Tk::ListBrowser::Item - List entry holding object.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
use Carp;

$VERSION =  0.01;

=head1 SYNOPSIS

 my $item = $listbrowser->add($entryname, @options);

 my $item = $listbrowser->get($entryname);

=head1 DESCRIPTION

This module creates an object that holds all information of every entry.
You will never need to create an item object yourself.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	
	my %args = @_;

	my $canv = delete $args{'-canvas'};
	croak 'You did not specify a canvas' unless defined $canv;

	my $data = delete $args{'-data'};

	my $hidden = delete $args{'-hidden'};
	$hidden = 0 unless defined $hidden;

	my $image = delete $args{'-image'};

	my $name = delete $args{'-name'};
	croak 'You did not specify an name' unless defined $name;

	my $text = delete $args{'-text'};
	$text = '' unless defined $text;
	
	my $self = {
		ANCHOR => 0,
		CANVAS => $canv,
		COLUMN => undef,
		DATA => $data,
		HIDDEN => $hidden,
		IMAGE => $image,
		NAME => $name,
		REGION => [0, 0, 0, 0],
		ROW => undef,
		SELECTED => 0,
		TEXT => $text,
		TFILL => undef,
	};
	bless $self, $class;
	return $self
}

=item B<anchor>I<($flag)>

If I<$flag> is set it makes the anchor rectangle of this entry visible.
Otherwise clears it.

=cut

sub anchor {
	my ($self, $flag) = @_;
	my $c = $self->canvas;
	my $p = $c->Subwidget('Canvas');
	$flag = 1 unless defined $flag;
	my $r = $self->crect;
	$self->{ANCHOR} = $flag;
	if ($flag) {
		my $fg = $c->cget('-foreground');
		$p->itemconfigure($r,
			-outline => $fg, # TODO should not be a hard coded color.
			-outlinestipple => 'gray75',
		);
	} else {
		my $outline;
		$outline = $c->cget('-selectbackground') if $self->selected;
		$p->itemconfigure($r,
			-outline => $outline,
			-outlinestipple => undef,
		);
	}
}

=item B<anchored>

Returns true if the anchor is set to this entry.

=cut

sub anchored { return $_[0]->{ANCHOR} }

sub canvas { return $_[0]->{CANVAS} }

sub cimage {
	my $self = shift;
	$self->{CIMAGE} = shift if @_;
	return $self->{CIMAGE}
}

=item B<clear>I<(?$flag?)>

Clears all visible items (text, image, anchor, selection) on the canvas belonging to this item.

=cut

sub clear {
	my $self = shift;
	my $c = $self->canvas->Subwidget('Canvas');
	for ($self->cimage, $self->ctext, $self->crect) {
		$c->delete($_) if defined $_;
	}
	$self->cimage(undef);
	$self->ctext(undef);
	$self->crect(undef);
	$self->region(0, 0, 0, 0);
}

=item B<column>I<(?$column?)>

Sets and returns the column number of this entry

=cut

sub column {
	my $self = shift;
	$self->{COLUMN} = shift if @_;
	return $self->{COLUMN}
}

sub crect {
	my $self = shift;
	$self->{CRECT} = shift if @_;
	return $self->{CRECT}
}

sub ctext {
	my $self = shift;
	$self->{CTEXT} = shift if @_;
	return $self->{CTEXT}
}

=item B<data>I<(?$data?)>

Sets and returns the data scalar assigned to this entry.

=cut

sub data {
	my $self = shift;
	$self->{DATA} = shift if @_;
	return $self->{DATA}
}

=item B<hidden>I<(?$flag?)>

Sets and returns the hidden flag belonging to this entry.

=cut

sub hidden {
	my $self = shift;
	$self->{HIDDEN} = shift if @_;
	return $self->{HIDDEN}
}

=item B<image>I<(?$image?)>

Sets and returns the image object belonging to this entry.

=cut

sub image {
	my $self = shift;
	$self->{IMAGE} = shift if @_;
	return $self->{IMAGE}
}

=item B<inregion>I<($x, $y)>

Returns true if the point at I<$x>, I<$y> is inside
the region of this entry.

=cut

sub inregion {
	my ($self, $x, $y) = @_;
	my ($cx, $cy, $cdx, $cdy) = $self->region;
	return '' unless $x >= $cx;
	return '' unless $x <= $cdx;
	return '' unless $y >= $cy;
	return '' unless $y <= $cdy;
	return 1
}

=item B<name>

Sets and returns name of this entry.

=cut

sub name { return $_[0]->{NAME} }

sub region {
	my $self = shift;
	$self->{REGION} = [@_] if @_;
	my $r = $self->{REGION};
	return @$r;
}

=item B<row>

Sets and returns the row number of this entry.

=cut

sub row {
	my $self = shift;
	$self->{ROW} = shift if @_;
	return $self->{ROW}
}

=item B<select>I<($flag)>

If I<$flag> is set it changes the look of this entry as selected.
Otherwise changes the look to un-selected it.

=cut

sub select {
	my ($self, $flag) = @_;
	$flag = 1 unless defined $flag;
	my $c = $self->canvas;
	my $p = $c->Subwidget('Canvas');
	my $r = $self->crect;
	my $t = $self->ctext;
	$self->{TFILL} = $p->itemcget($t, '-fill') unless defined $self->{TFILL};
	$self->{SELECTED} = $flag;
	if ($flag) {
		$p->itemconfigure($r,
			-fill => $c->cget('-selectbackground'),
			-outline => $c->cget('-selectbackground'),
		);
		$p->raise($self->cimage);
		$p->raise($t);
		$p->itemconfigure($t, 
			-fill => $c->cget('-selectforeground'),
		);
	} else {
		my $outline= $c->cget('-foreground');
		$outline = undef unless $self->anchored;
		$p->itemconfigure($r,
			-fill => undef,
			-outline => $outline,
		);
		$p->itemconfigure($t, 
			-fill => $self->{TFILL},
		);
	}
}

=item B<selected>

Returns true if this entry is belonging to the selection.

=cut

sub selected { return $_[0]->{SELECTED} }

=item B<text>I<(?$string?)>

Sets and returns the text string belonging to this entry.

=cut

sub text {
	my $self = shift;
	$self->{TEXT} = shift if @_;
	return $self->{TEXT}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=back

=cut

