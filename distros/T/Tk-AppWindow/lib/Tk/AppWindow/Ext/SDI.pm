package Tk::AppWindow::Ext::SDI;

=head1 NAME

Tk::AppWindow::Ext::SDI - single document interface

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.17";

use base qw( Tk::AppWindow::Ext::MDI );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -contentmanagerclass => 'Tk::MyContentHandler',
    -extensions => ['SDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a single document interface to your application.
Inherits L<Tk::AppWindow::Ext::MDI>. See also there.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	return $self;
}

sub CmdDocNew {
	my $self = shift;
	if ($self->CmdDocClose) {
		return $self->SUPER::CmdDocNew(@_)
	}
	return 0
}

sub CommandDocSaveAll {
	return ()
}

sub ContentSpace {
	return $_[0]->WorkSpace;
}

sub CreateInterface {}

sub docOpenDialog {
	my $self = shift;
	return $self->pickFileOpen(@_);
}

sub MenuSaveAll {
	return ()
}

sub ToolSaveAll {
	return () 
}

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::Ext::MDI>

=back

=cut

1;

__END__




