package Tk::QuickForm::CTextItem;

=head1 NAME

Tk::QuickForm::CTextItem - Entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
use Tie::Watch;
Construct Tk::Widget 'CTextItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CBooleanItem;
 my $bool = $window->CBooleanItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::Frame>

Provides a text entry widget for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

All options, except I<-textvariable>, of L<Tk::Entry> are available.

=over 4

=item Name: B<errorColor>

=item Class: B<ErrorColor>

=item Switch: B<-errorcolor>

Foreground color for the entry widget when validation fails.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#ff0000'],
		DEFAULT => [$self->Subwidget('Entry')],
	);
	$self->after(1, ['validate', $self]);
}

sub createHandler {
	my ($self, $var) = @_;
	my $e = $self->Entry(
		-textvariable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub validUpdate {
	my ($self, $flag) = @_;
	unless (defined $self->cget('-entryforeground')) {
		$self->configure(-entryforeground => $self->Subwidget('Entry')->cget('-foreground'));
	}
	if ($flag) {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-errorcolor'));
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

=item L<Tk::Entry>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
