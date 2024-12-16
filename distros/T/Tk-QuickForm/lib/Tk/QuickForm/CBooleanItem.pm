package Tk::QuickForm::CBooleanItem;

=head1 NAME

Tk::QuickForm::CBooleanItem - Checkbutton widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.06';

use Tk;
use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
Construct Tk::Widget 'CBooleanItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CBaseooleanItem;
 my $bool = $window->CBooleanItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>. Provides a Checkbutton field for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-variable>, of L<Tk::Checkbutton> are available.

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => [$self->Subwidget('Check')],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $c = $self->Checkbutton(
		-variable => $var,
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Check => $c);
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Checkbutton>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
