package Tk::QuickForm::CFolderItem;

=head1 NAME

Tk::QuickForm::CFolderItem - Folder select entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::QuickForm::CFileItem);
Construct Tk::Widget 'CFolderItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CFolderItem;
 my $bool = $window->CFolderItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CFileItem>. Provides a folder entry with dialog for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 CONFIG VARIABLES

All options, except I<-textvariable>, of L<Tk::Entry> are available.

=over 4

=item Switch: B<-image>

Image to be used for the dialog button.

=back

=cut

sub createHandler {
	my ($self, $var) = @_;
	$self->SUPER::createHandler($var);
	$self->Subwidget('Select')->configure(
		-command => sub {
			my $file = $self->chooseDirectory(
# 				-initialdir => $initdir,
				-popover => $self->toplevel,
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	);
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

=item L<Tk::QuickForm::CFileItem>

=item L<Tk::QuickForm::CTextItem>


=back

=cut




1;

__END__
