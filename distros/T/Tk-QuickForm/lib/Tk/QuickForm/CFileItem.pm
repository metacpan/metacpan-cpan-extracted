package Tk::QuickForm::CFileItem;

=head1 NAME

Tk::QuickForm::CFileItem - File select entry widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use base qw(Tk::Derived Tk::QuickForm::CTextItem);
Construct Tk::Widget 'CFileItem';

use File::Basename;

=head1 SYNOPSIS

 require Tk::QuickForm::CFileItem;
 my $bool = $window->CFileItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CTextItem>. Provides a file entry with dialog for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

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
		-state => [[$self->Subwidget('Entry'), $self->Subwidget('Select')]],
		DEFAULT => [$self->Subwidget('Entry')],
	);
}

sub buttonClicked {
	my $self = shift;
	my $var = $self->cget('-textvariable');
	my %opt = ();
	if ($$var ne '') {
		my $base = basename($$var);
		$opt{'-initialfile'} = $base if $base ne '';
		my $dir = dirname($$var);
		$opt{'-initialdir'} = $dir if $dir ne '';
	}
	my ($file) = $self->quickform->pickFile(%opt);
	$$var = $file if defined $file;
}

sub createHandler {
	my ($self, $var) = @_;
	$self->SUPER::createHandler($var);
	my $b = $self->Button(
		-command => ['buttonClicked', $self],
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
