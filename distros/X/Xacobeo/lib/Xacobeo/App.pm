package Xacobeo::App;

=head1 NAME

Xacobeo::App - Application

=head1 SYNOPSIS

	use Xacobeo::App;
	
	my $xacobeo = Xacobeo::App->get_app();
	
	my $window = $xacobeo->new_window();
	$window->load_file($source, $type);
	
	$xacobeo->load_plugins();
	
	# Start the main loop
	Gtk2->main();

=head1 DESCRIPTION

Instance to the main application. This singleton is used to manage the life-time
of the application, its widgets (specially the main windows) and to setup the
application.
=head1 PROPERTIES

The following properties are defined:

=head2 conf

A reference to the main configuration singleton.

=head2 windows

The windows available.

=head1 METHODS

The package defines the following methods:

=cut

use strict;
use warnings;

use File::Spec::Functions;

use Xacobeo::Conf;
use Xacobeo::GObject;
use Xacobeo::I18n;
use Xacobeo::UI::Window;


Xacobeo::GObject->register_package('Gtk2::Window' =>
	properties => [
		Glib::ParamSpec->scalar(
			'windows',
			"Windows",
			"The windows openned so far",
			['readable', 'writable', 'construct-only'],
		),

		Glib::ParamSpec->object(
			'conf',
			"Configuration",
			"A reference to the main configuration singleton",
			'Xacobeo::Conf',
			['readable', 'writable', 'construct-only'],
		),
	],
);


my $INSTANCE = __PACKAGE__->init();



=head2 get_app

Returns the current application instance. This class is a singleton so there's
no constructor.

=cut

sub get_app {
	return $INSTANCE;
}


sub init {
	my $class = shift;
	my ($dir) = @_;

	my $conf = Xacobeo::Conf->get_conf;
	Xacobeo::I18n->init($conf->share_dir('locale'));
	
	$INSTANCE = $class->SUPER::new(
		windows => [],
		conf    => $conf,
	);
}



=head2 get_windows

Returns the windows created so far.

=cut

sub get_windows {
	my $self = shift;
	return @{ $self->windows };
}


=head2 new_window

Creates a new window and shows it.

=cut

sub new_window {
	my $self = shift;

	my $window = Xacobeo::UI::Window->new();
	$window->show_all();

	$window->signal_connect(destroy => sub { $self->callback_destroy(@_); });
	push @{ $self->{windows} }, $window;

	return $window;
}


sub callback_destroy {
	my $self = shift;
	my ($window) = @_;
	my @windows = grep { $_ != $window } @{ $self->windows };
	
	$self->windows(\@windows);
	
	if (@windows == 0) {
		Gtk2->main_quit();
	}
}



=head2 load_plugins

Loads the plugins that are available.

=cut

sub load_plugins {
	my $self = shift;

	my $conf = $self->conf;

	# Load plugins
	foreach my $folder ($conf->plugin_folders) {
		next unless -d $folder;
		eval {

			opendir my $handle, $folder or die $!;
			while (my $entry = readdir $handle) {
				next if $entry =~ /^\./;

				my $file = catfile($folder, $entry);
				next if -d $file or ! -e $file;

				eval {
					$self->load_plugin($file);
					1;
				} or do {
					warn __x("Failed to load plugin described by {file}; {error}", file => $file, error => $@);
				};
			}
			closedir $handle;
			1;
		} or do {
			warn __x("Failed to scan folder {folder}; {error}", folder => $folder, error => $@);
		};
	}
}


=head2 load_plugin

Loads a plugin based on the given description file.

Parameters:

=over

=item * $file

The file describing the plugin.

=back

=cut

sub load_plugin {
	my $self = shift;
	my ($file) = @_;

	my $keyfile = Glib::KeyFile->new();
	$keyfile->load_from_file($file, 'none');

	my $group = 'Xacobeo Plugin';
	if (! $keyfile->has_group($group)) {
		die __("File is not describing a Xacobeo plugin");
	}

	my $plugin;
	if ($keyfile->has_key($group, 'Package')) {
		my $package = $keyfile->get_string($group, 'Package');

		$plugin = eval qq{require $package;};
		if ($@) {
			die __x("Error while load package {package}; {error}", package => $package, error => $@);
		}
		elsif (! $plugin) {
			die __x("Package {package} failed to return a plugin", package => $package);
		}
	}
	elsif ($keyfile->has_key($group, 'Script')) {
		my $script = $keyfile->get_string($group, 'Script');
		$plugin = do $script;

		if ($@) {
			die __x("Can't load script {script}; {error}", script => $script, error => $@);
		}
		elsif (! $plugin) {
			die __x("Script {script} failed to return a plugin", script => $script);
		}
	}
	else {
		die __("File is missing the key Package or Script");
	}

	$plugin->init($self);
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

