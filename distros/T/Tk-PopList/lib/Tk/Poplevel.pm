package Tk::Poplevel;

=head1 NAME

Tk::Poplevel - Popping a toplevel without decoration relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.09';

use base qw(Tk::Derived Tk::Toplevel);

use Tk;

Construct Tk::Widget 'Poplevel';

=head1 SYNOPSIS

 require Tk::Poplevel;
 my $pop = $window->Poplevel(@options,
    -widget => $somewidget,
 );
 $pop->popUp;

=head1 DESCRIPTION

This widget pops a toplevel without ornaments relative to the widget specified in the B<-widget> option.
It aligns its size and position to the widget.

Clicking outside the toplevel will pop it down.

=head1 OPTIONS

Accepts all the options of a Toplevel widget;

=over 4

=item B<-confine>

Default value is 0.
If set the popup will have the equal with of the widget.

=item B<-popalign>

Default value 'left'.
Can be 'left' or 'right'.
This is the preferred horizontal alignment.
Does nothing when B<-confine> is set.

=item B<-popdirection>

Default value 'down'.
Can be 'up' or 'down'.
Specifies if the popup should be preferrably above or below the widget.
Does nothing when B<-confine> is set.

=item B<-widget>

Set and return a reference to the widget the Poplevel should pop relative to.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);

	$self->{POPDIRECTION} = '';
	
	$self->overrideredirect(1);
	$self->withdraw;

	my $parent = $self->parent;
	my $bindsub = $parent->bind('<Button-1>');
	if ($bindsub) {
		$parent->bind('<Button-1>', sub {
			$bindsub->Call;
			$self->popDown;
		});
	} else {
		$parent->bind('<Button-1>',  [$self, 'popDown'] );
	}
	
	$self->ConfigSpecs(
		-borderwidth => [$self, 'borderWidth', 'BorderWidth', 1],
		-confine => ['PASSIVE', undef, undef, 0],
		-popalign => ['PASSIVE', undef, undef, 'left'],
		-popdirection => ['PASSIVE', undef, undef, 'down'],
		-relief => [$self, 'relief', 'Relief', 'raised'],
		-widget => ['PASSIVE'],
		DEFAULT => [ $self ],
	);
}

=item B<calculateHeight>

For you to overwrite.
Returns the requested height of the B<Polevel>.

=cut

sub calculateHeight {
	return $_[0]->reqheight;
}

=item B<calculateWidth>

For you to overwrite.
Returns the requested width of the B<Polevel>.

=cut

sub calculateWidth {
	return $_[0]->reqwidth;
}

sub ConfigureSizeAndPos {
	my $self = shift;

	my $widget = $self->cget('-widget');
	my $screenheight = $self->vrootheight;
	my $screenwidth = $self->vrootwidth;
	my $confine = $self->cget('-confine');
	my $preferred = $self->cget('-popdirection');
	my $align = $self->cget('-popalign');

	my $height = $self->calculateHeight;

	my $width;
	if ($confine) {
		$width = $widget->width;
	} else {
		$width = $self->calculateWidth;
	}

	my $x = $widget->rootx;
	unless ($confine) {
		my $flag;
		if ($align eq 'left') {
			$flag = ($x + $width > $screenwidth);
		} else {
			$flag = ($x + $widget->width - $width > 0)
		}
		if ($flag) {
			$x = $x - ($width - $widget->width);
		}
	}

	my $y = $widget->rooty;

	my $flag;
	if ($preferred eq 'up') {
		$flag = ($y - $height > 0)
	} else {
		$flag = ($y + $height + $widget->height > $screenheight)
	}
	
	if ($flag) {
		$self->{POPDIRECTION} = 'up';
		$y = $y - $height;
	} else {
		$self->{POPDIRECTION} = 'down';
		$y = $y + $widget->height;
	}
	$self->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
}

=item B<popDirection>

Returns the direction of the popup. It is '' when not yet calculated. Can be 'up' or 'down'.

=cut

sub popDirection {
	return $_[0]->{POPDIRECTION}
}


=item B<popDown>

Hides the PopList.

=cut

sub popDown {
	my $self = shift;
	return unless $self->ismapped;
	$self->withdraw;
	$self->parent->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
}

=item B<popFlip>

Hides the PopList if it shown. Shows the PopList if it is hidden.

=cut

sub popFlip {
	my $self = shift;
	if ($self->ismapped) {
		$self->popDown
	} else {
		$self->popUp
	}
}

=item B<popUp>

Shows the PopList.

=cut

sub popUp {
	my $self = shift;

	return if $self->ismapped;

	$self->ConfigureSizeAndPos;
	$self->deiconify;
	$self->raise;
	$self->{'_BE_grabinfo'} = $self->grabSave;
	$self->parent->grabGlobal;
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk>

=item L<Tk::Toplevel>

=item L<Tk::Listbox>

=back

=cut

1;
__END__

