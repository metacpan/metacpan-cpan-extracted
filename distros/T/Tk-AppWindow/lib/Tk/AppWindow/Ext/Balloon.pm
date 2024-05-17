package Tk::AppWindow::Ext::Balloon;

=head1 NAME

Tk::AppWindow::Ext::Balloon - Adding balloon functionality

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.03";
use Tk;
require Tk::Balloon;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Balloon'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a balloon widget to your application

=head1 CONFIG VARIABLES

None.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{BALLOON} = $self->GetAppWindow->Balloon;
	return $self;
}

=head1 METHODS

=over 4

=item B<Attach>I<($widget => $message)>

Attaches a balloon with I<$message> to I<$widget>.

=cut

sub Attach {
	my $self = shift;
	$self->{BALLOON}->attach(@_);
}

=item B<Balloon>

Returns a reference to the Balloon widget.

=cut

sub Balloon {
	return $_[0]->{BALLOON}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::Balloon>

=back

=cut

1;


