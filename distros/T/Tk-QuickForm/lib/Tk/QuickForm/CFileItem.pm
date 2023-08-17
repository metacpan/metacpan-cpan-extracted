package Tk::QuickForm::CFileItem;

=head1 NAME

Tk::QuickForm::CFileItem - File select entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CFileItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CFileItem;
 my $bool = $window->CFileItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides a file entry with dialog for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

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
	my $b = $self->Button(
		-command => sub {
			my $file = $self->getOpenFile(
# 				-initialdir => $initdir,
# 				-popover => 'mainwindow',
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$self->Advertise(Select => $b);
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
