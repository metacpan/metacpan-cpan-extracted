package Tk::AppWindow::BaseClasses::Plugin;

=head1 NAME

Tk::AppWindow::BaseClasses::Plugin - Baseclass for all plugins.

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.07";
use vars '$AUTOLOAD';

=head1 SYNOPSIS

 #This is useless
 my $plug = Tk::AppWindow::BaseClasses::Plugin->new($frame);

 #This is what you should do
 package My::App::Path::Plugins::MyPlugin
 use base(Tk::AppWindow::BaseClasses::Plugin);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    if (defined $self) {
       ...
    }
    return $self
 }

=head1 DESCRIPTION

A plugin is different from an extension in a couple of ways:

 - A plugin can be loaded and unloaded by the end user.
   If they do not desire the functionality they can simply 
   unload it.
 - A plugin can not define config variables

This is a base class you can inherit to write your own plugin.

It autoloads methods from the mainwindow class.

=cut

sub new {
	my ($proto, $window, @required) = (@_);
	my $class = ref($proto) || $proto;
	my $self = {
		APPWINDOW => $window,
	};
	bless ($self, $class);
	for (@required) {
		unless ($self->extExists($_)) {
			croak "Extension $_ is not loaded";
			return undef
		}
	}
	$self->after(10, ['CheckSettingsPage', $self]);
	return $self
}

sub AUTOLOAD {
	my $self = shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD =~ s/^.*:://;
	return $self->{APPWINDOW}->$AUTOLOAD(@_);
}

sub _getnb {
	my $self = shift;
	my $set = $self->extGet('Settings');
	my $nb;
	$nb = $set->NBWidget if defined $set;
	return $nb;
}

=head1 METHODS

=over 4

=item B<CanQuit>

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=cut

sub CanQuit { return 1 }

sub CheckSettingsPage {
	my $self = shift;
	my $nb = $self->_getnb;
	return unless defined $nb;
	my $set = $self->extGet('Settings');
	$set->externalAdd($self->SettingsPage);
}

=item B<GetAppWindow>

Returns a reference to the toplevel frame. The toplevel frame should be a Tk::AppWindow class.

=cut

sub GetAppWindow { return $_[0]->{APPWINDOW} }

=item B<MenuItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

=cut

sub MenuItems {
	return ();
}

=item B<Name>

returns the module name of $self, without the path. So, if left uninherited, it returns 'Plugin'.

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

sub ReConfigure {
	return 1
}

=item B<ToolItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

=cut

=item B<SettingsPage>

Returns an empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. 
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

sub ToolItems {
	return ();
}

=item B<Quit>

Does nothing. It is there for you to overwrite. Here you do everything needed when the application
is to terminate.

=cut

sub Quit { }

=item B<UnLoad>

Removes the settings page for this plugin from the settings dialog if applicable.
Returns 1. When overwriting this method, make a call to SUPER::Unload to include this. and do what
is needed to completely unload your plugin.

=cut

sub Unload {
	my $self = shift;
	my @sp = $self->SettingsPage;
	my $set = $self->extGet('Settings');
	if (defined $set) {
		while (@sp) {
			my $page = shift @sp;
			$set->externalRemove($page);
			shift @sp
		}
	}
	return 1;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow>

=back

=cut

1;
__END__




