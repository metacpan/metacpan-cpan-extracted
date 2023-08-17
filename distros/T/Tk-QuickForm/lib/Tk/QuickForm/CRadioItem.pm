package Tk::QuickForm::CRadioItem;

=head1 NAME

Tk::QuickForm::CRadioItem - Array of Radiobuttons for Tk::QuickForm.

=cut

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
Construct Tk::Widget 'CRadioItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CRadioItem;
 my $bool = $window->CRadioItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>.  Providess a row of Radiobuttons for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-variable>, of L<Tk::Radiobutton> are available.

=over 4

=item Switch: B<-values>

The list of possible values.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	for (@$values) {
		$self->Radiobutton(
			-text => $_,
			-value => $_,
			-variable => $var,
		)->pack(-side => 'left', -padx => 2, -pady => 2);
	}
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Radiobutton>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
