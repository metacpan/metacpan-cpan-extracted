package Tk::YAMessage;

=head1 NAME

Tk::YAMessage - Yet another message box

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Tk;
use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'YAMessage';

=head1 SYNOPSIS

 my $dialog = $window->YAMessage(
	-image = $window->Getimage('info');
	-text => 'Hello',
 );
 $dialog->Show;

=head1 DESCRIPTION

Provides a basic, less noisy, replacement for L<Tk::MessageBox>.
Inherits L<Tk::YADialog>.

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-image>

Default value none.
Specify the image to be shown. Must be a Tk::Image object.

=item Switch: B<-text>

Default value none.
Specify the text to be shown.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	unless (exists $args->{'-buttons'}) {
		$args->{'-buttons'} = ['Ok'];
		$args->{'-defaultbutton'} = 'Ok';
	}
	$self->SUPER::Populate($args);
	
	my $i = $self->Label->pack(-side => 'left', -padx => 10, -pady =>10);
	my $t = $self->Label()->pack(-side => 'left', -padx => 10, -pady =>10);
	$self->ConfigSpecs(
		-image => [$i],
		-text => [$t],
		DEFAULT => ['SELF'],
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

=item L<Tk::YADialog>

=back

=cut

1;
