package Tk::PopColor;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';
use Tk;

use base qw(Tk::Derived Tk::Poplevel);

Construct Tk::Widget 'PopColor';

require Tk::ColorPicker;

=head1 NAME

Tk::PopColor - Pop A Tk::ColorPicker widget relative to a widget.

=head1 SYNOPSIS

  use Tk::PopColor;
  my $pop = $window->PopColor(
     -widget => $widget,
  );
  $pop->popUp;

=head1 DESCRIPTION

Inherits L<Tk::Poplevel>

Tk::PopColor is a L<Tk::Poplevel> containing  a L<Tk::ColorPicker>.
See these two for options and methods.

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my $picker = $self->ColorPicker(
	)->pack(-fill => 'both');
	$self->Advertise(Picker => $picker);
	$self->ConfigSpecs(
		-borderwidth => [$self, 'borderWidth', 'BorderWidth', 1],
		-relief => [$self, 'relief', 'Relief', 'raised'],
		DEFAULT => [ $picker ],
	);

	$self->Delegates(
		DEFAULT => $picker,
	);
}

sub popDown {
	my $self = shift;
	my $color = $self->compoundColor;
	$self->historyAdd($self->compoundColor);
	$self->SUPER::popDown
}

sub popCancel {
	my $self = shift;
	$self->SUPER::popDown
}

sub popUp {
	my $self = shift;
	$self->ConfigMode(1);
	$self->SUPER::popUp;
	$self->historyUpdate;
	$self->after(300, ['ConfigMode', $self, 0]);;
}


=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;
__END__
