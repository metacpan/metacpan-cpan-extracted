package Xacobeo::Ex::ClipboardLoad;

=head1 NAME

Xacobeo::Ex::ClipboardLoad - Test plugin

=head1 DESCRIPTION

Sample plugin that allows to load an XML document based on the contents of the
clipboard.

The plugin adds the entry I<Load from clipboard> under the I<File> main menu.
The plugin can also be activated through the shortcut I<CTRL SHIFT L>.

=head1 USAGE

Copy the file examples/cliboard.plugin into $HOME/.config/xacobeo/plugins/ and
add examples/Xacobeo into your PERL5LIB path.

Or copy examples/Xacobeo/Ex/ClipboardLoad.pm somewhere and add the full path
to the variable I<Script> in the file F<cliboard.plugin>. For instance if you
copy the perl module to F<$HOME/.config/xacobeo/plugins/ and that your user name
is I<me> then use:

	Script=/home/me/.config/xacobeo/plugins/ClipboardLoad.pm

=cut

use Glib qw(TRUE FALSE);
use base 'Xacobeo::Plugin';

use strict;
use warnings;

use Xacobeo::Document;

our $VERSION = '0.03';


sub init {
	my $self = shift;
	my ($xacobeo) = @_;

	my ($window) = $xacobeo->get_windows();	
	$window->statusbar->display("Plugin Loaded!");

	# Build an action group, this is where we define the name, shortcut, icon and
	# the callback for our actions.
	my $actions = Gtk2::ActionGroup->new("XacobeoTestPluginActions");
	$actions->add_actions([
		# Entries (name, stock id, label, accelerator, tooltip, callback)
		[
			'FileNewFromClipboard',
			'gtk-paste',
			"_Load from clipboard",
			'<control><shift>L',
			"Load a file from the clipboard",
			sub { $self->load_from_clipboard(@_, $window) }
		],
	]);

	
	# Inject our new actions into the existing application
	my $ui_manager = $window->ui_manager;
	$ui_manager->insert_action_group($actions, 0);
	$ui_manager->add_ui(
		$ui_manager->new_merge_id,
		'/MenuBar/FileMenu/FilePlaceholder_1',
		'FileNewFromClipboard',
		'FileNewFromClipboard',
		'menuitem',
		FALSE
	);
}


sub load_from_clipboard {
	my $self = shift;
	my ($action, $window) = @_;

	# Prepare the system clipboard
	my $selection = Gtk2::Gdk::Atom->new('CLIPBOARD');
	my $clipboard = Gtk2::Clipboard->get($selection);
	
	# Get the xml from clipboard
	my $xml = $clipboard->wait_for_text;
	return unless defined $xml;
	
	# Load the temporary xml file
	my $document = Xacobeo::Document->new_from_string($xml, 'xml');
	$window->set_title('clipboard');
	$window->load_document($document);
}


__PACKAGE__->load();


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.
Jozef Kutej E<lt>jkutej@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez, Jozef Kutej.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
