package Tk::AppWindow::BaseClasses::Extension;

=head1 NAME

Tk::AppWindow::BaseClasses::Extension - Baseclass for all extensions in this framework

=cut

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
$VERSION="0.08";
use Carp;

=head1 SYNOPSIS

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::Extension->new($mainwindow);

 #This is what you should do
 package Tk::AppWindow::Ext::MyExtension
 use base(Tk::AppWindow::BaseClasses::Extension);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=head1 DESCRIPTION

Tk::AppWindow::BaseClasses::Extension is the base object for all extenstions in this Tk::AppWindow framework. All extensions inherit
this class. It has access to the Tk::AppWindow object and autoloads its methods.
It has the core mechanisms in place if your extensions need to reconfigure or veto a close command.

Use this class as a basis to define your own extension.

=cut

sub new {
	my ($proto, $window) = (@_);
	my $class = ref($proto) || $proto;
	my $self = {
		APPWINDOW => $window,
	};
	bless ($self, $class);

	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD =~ s/^.*:://;
	return $self->{APPWINDOW}->$AUTOLOAD(@_);
}

=head1 METHODS

=over 4

=item B<CanQuit>

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=cut

sub CanQuit { return 1 }

=item B<GetAppWindow>

Returns a reference to the MainWindow widget.

=cut

sub GetAppWindow { return $_[0]->{APPWINDOW} }

=item B<MenuItems>

Returns an empty list. It is there for you to overwrite. It is called by the B<MenuBar> extension. You can return a list
with menu items here. For details on the format see L<Tk::AppWindow::Ext::MenuBar>

=cut

sub MenuItems {
	return ();
}

=item B<Name>

returns the module name of $self, without the path. So, if left uninherited, it returns 'Extension'.

=cut

sub Name {
	my $self = shift;
	my $name = ref $self;
	$name =~ s/.*:://;
	return $name
}

=item B<ReConfigure>

Does nothing. It is called when the user clicks the Apply button in the settings dialog. Overwrite it to act on 
modified settings.

=cut

sub ReConfigure {}

=item B<Require>I<(@extensions)>

Only call this during extension construction.
Loads @extensions. ignores already loaded ones.
returns true on succes.

=cut

sub Require {
	my $self = shift;
	my $args = $self->GetArgsRef;
	my $success = 1;
	while (@_) {
		my $m = shift;
		unless ($self->extExists($m)) {
			$self->extLoad($m, $args);
			$success = '' unless $self->extExists($m);
		}
	}
	return $success
}

=item B<SettingsPage>

Returns an empty list. It is there for you to overwrite. It is called by the B<Settings> extension. 
You can return a paired list of pagenames and widget.

 sub SettingsPage {
.   return (
       'Some title' => ['MyWidget', @options],
    )
 }

If 'MyWidget' has an 'Apply' method it will be called when you hit the 'Apply' button.

=cut

sub SettingsPage {
	return ();
}

=item B<ToolItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<ToolBar> extension. You can return a list
with menu items here. For details on the format see L<Tk::AppWindow::Ext::ToolBar>

=cut

sub ToolItems {
	return ();
}

=item B<Quit>

Does nothing. It is there for you to overwrite. Here you do everything needed to terminate.

=cut

sub Quit { }

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=back

=cut

1;
__END__



