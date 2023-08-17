package Tk::QuickForm::CFontItem;

=head1 NAME

Tk::QuickForm::CFontItem - Font select entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CFontItem';
require Tk::FontDialog;


=head1 SYNOPSIS

 require Tk::QuickForm::CBooleanItem;
 my $bool = $window->CBooleanItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides a font entry with dialog for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-textvariable>, of L<Tk::Entry> are available.

=over 4

=item Switch: B<-image>

Image to be used for the dialog button.

=back

=cut

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-image => [$self->Subwidget('Select')],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$self->Subwidget('Entry')],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	$self->SUPER::createHandler($var);
	my @bopt = ();
	my $but = $self->Button(@bopt,
		-command => sub {
			my $dialog = $self->FontDialog(
				-title => "Select font",
				-initfont => $$var,
			);
			my $font = $dialog->Show(-popover => $self->toplevel);
			if (defined $font) {
				$$var =  $dialog->GetDescriptiveFontName($font)
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Select => $but);
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=item L<Tk::QuickForm::CTextItem>

=back

=cut



1;

__END__
