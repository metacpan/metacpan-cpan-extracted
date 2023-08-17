package Tk::QuickForm::CScaleItem;

=head1 NAME

Tk::QuickForm::CScaleItem - Scale widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
Construct Tk::Widget 'CScaleItem';
require Tk::Scale;

=head1 SYNOPSIS

 require Tk::QuickForm::CScaleItem;
 my $bool = $window->CScaleItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>.  Provides a Scale widget for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-variable>, of L<Tk::Scale> are available.

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => [$self->Subwidget('Scale')],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $c = $self->Scale(
		-orient => 'horizontal',
		-variable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Scale => $c);
}


=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Scale>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut


1;

__END__
