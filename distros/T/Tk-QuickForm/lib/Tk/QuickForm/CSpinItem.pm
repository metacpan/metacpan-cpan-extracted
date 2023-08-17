package Tk::QuickForm::CSpinItem;

=head1 NAME

Tk::QuickForm::CSpinItem - Spinbox widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use base qw(Tk::Derived Tk::QuickForm::CTextItem);
use Tie::Watch;
Construct Tk::Widget 'CSpinItem';
require Tk::Spinbox;

=head1 SYNOPSIS

 require Tk::QuickForm::CSpinItem;
 my $bool = $window->CSpinItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>.Provides a Spinbox widget for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-textvariable>, of L<Tk::Spinbox> are available.

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-entryforeground => ['PASSIVE', undef, undef, $self->cget('-foreground')],
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#ff0000'],
		DEFAULT => [$self->Subwidget('Entry')],
	);
	$self->after(1, ['validate', $self]);
}

sub createHandler {
	my ($self, $var) = @_;
	my $e = $self->Spinbox(
		-textvariable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Spinbox>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
