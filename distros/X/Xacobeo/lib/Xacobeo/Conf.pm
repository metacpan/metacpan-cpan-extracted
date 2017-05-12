package Xacobeo::Conf;

=head1 NAME

Xacobeo::Conf - Application's configuration.

=head1 SYNOPSIS

	use Xacobeo::Conf;
	
	my $conf = Xacobeo::Conf->get_conf;
	
	my $icon = $conf->share_file('images', 'xacobeo.png'); # /usr/share/images/xacobeo.png
	my $po_folder = $conf->share_folder('locale');         # /usr/share/locale

=head1 DESCRIPTION

Utility class that provides a way for accessing all configuration parameters
that are needed at runtime..

=head1 PROPERTIES

The following properties are defined:

=head2 dir

The root directory where the application has been installed.

=head1 METHODS

The following methods are available:

=cut

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;
use File::BaseDir;

use Xacobeo::GObject;

Xacobeo::GObject->register_package('Glib::Object' =>
	properties => [
		Glib::ParamSpec->scalar(
			'dir',
			"Dir",
			"The root folder of the application's installation",
			['readable', 'writable', 'construct-only'],
		),
	],
);

my $XDG = File::BaseDir->new();
my $INSTANCE = __PACKAGE__->init();


=head2 get_conf

Returns the current configuration instance. This class is a singleton so there's
no constructor.

=cut

sub get_conf {
	return $INSTANCE;
}


sub init {
	my $class = shift;
	my ($dir) = @_;
	
	$dir ||= find_app_folder();

	$INSTANCE = $class->SUPER::new(dir => $dir);
}


=head2 share_dir

Returns the path of a folder in the application's I<share> directory.

Parameters:

=over

=item * @path

The path parts relative to the share directory.

=back

=cut

sub share_dir {
	my $self = shift;
	return catdir($self->dir, 'share', @_); 
}


=head2 share_file

Returns the path of a file in the application's I<share> directory.

Parameters:

=over

=item * @path

The path parts relative to the share directory.

=back

=cut

sub share_file {
	my $self = shift;
	return catfile($self->dir, 'share', @_); 
}


=head2 app_name

Returns the application's name.

=cut

sub app_name {
	return "Xacobeo";
}


=head2 plugin_folders

Returns the folders that are scanned for plugins.

=cut

sub plugin_folders {
	my $self = shift;
	my %seen;
	return map { $seen{$_}++ ? () : catdir($_, 'xacobeo', 'plugins') }
		$XDG->config_home,
		$XDG->config_dirs
	;
}


# Return the root folder of the application once installed. The 'root' folder is
# the one where the installation is done, the root folder hierarchy is as
# follows:
#
# (root)
# |-- bin
# |-- lib
# |   `-- perl5
# |       |-- Xacobeo
# |       `-- i486-linux-gnu-thread-multi
# |               `-- Xacobeo
# |           `-- auto
# |               `-- Xacobeo
# |-- man
# |   |-- man1
# |   `-- man3
# `-- share
#     |-- applications
#     |-- pixmaps
#     `-- xacobeo
sub find_app_folder {
	return catdir($FindBin::Bin, '..');
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

