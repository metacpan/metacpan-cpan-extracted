package Win32::Palm::Install;
$VERSION = '0.3';
use strict;
use Win32API::Registry qw (:ALL);
use Win32::Palm::Install::UsersDat;
use File::Basename;
use File::Copy;
use File::Spec;
use Carp;
use vars qw( $AUTOLOAD );

=head1 NAME

Win32::Palm::Install - Simple installer for palm.

=cut

{
# Encapsulated class data

	my %attr_data = (
		_PalmPath	=> 1,
		_PalmInstallDir => 1,
		_PalmSync	=> 1,
		_UserEntry	=> 1 
			);	
}


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = { 
		_PalmPath	=> "",
		_PalmInstallDir => "",
		_PalmSync	=> "",
		_UserEntry	=> ""
		   };

	bless $self, $class;
	$self->_init();
	
	return $self;
}

sub install {
	my ($self, $filename, $username) = @_;

	# break up filename, and check extension!
	my ($name, $path, $suffix) = fileparse( $filename, ( '\.prc', '\.pdb', '\.pqa') );
	croak "Unknown filetype!" unless $suffix;

	# Do we have that user?
	my $ud = $self->get_UserEntry;
	my $found;
	foreach my $ue ( $ud->get_UserEntry() ) {
		if ( $username eq $ue->get_LongName() ) {	
			$found = $ue;
			last;
		}
	}
	croak "No user found by name $username!" unless $found;

	my $syncid = sprintf("Install%d", $found->get_HotsyncID);
	my $palmsync = $self->get_PalmSync;
	my $fileto = File::Spec->catfile(
					$self->get_PalmPath(), 
		     		$found->get_DirName(), 
		     		$self->get_PalmInstallDir(), 
		     		$name . $suffix
					);
	copy($filename, $fileto);
	my $key;
	RegOpenKeyEx( HKEY_CURRENT_USER, $palmsync, 0, KEY_WRITE, $key );
	RegSetValueEx( $key, $syncid, 0, REG_DWORD, 1 );
	RegCloseKey($key);
}

sub _init {
	my $self = shift;

	my $palmkeyroot;
	my $palmpath;
	foreach my $try ( ("U.S. Robotics", "Palm Computing", "Palm", "Palm Inc." ) ) {
		my $temproot = "Software\\$try\\Pilot Desktop";
		my $key;
		RegOpenKeyEx( HKEY_CURRENT_USER, "$temproot\\Core", 0, KEY_READ, $key);

		if ( $key ) {
			$palmkeyroot = $temproot;
			my $t;
			RegQueryValueEx($key, "Path", [], $t, $palmpath, [] );
			RegCloseKey($key);
		}
	}

	$self->set_PalmPath( $palmpath );

	# Search for user's install directory
	my $palmman = "$palmkeyroot\\HotSync Manager";
	$self->set_PalmSync( $palmman );
	my $palminstalldir;
	my $key;
	RegOpenKeyEx( HKEY_CURRENT_USER, "$palmman", 0, KEY_READ, $key);
	for (my $i=0; $i<64; $i++) {
		my ($name, $lname, $class, $lclass, $subkey, $t, $d);
		if ( RegEnumKeyEx( $key, $i, $name, $lname, [], $class, $lclass, [])) {
			RegOpenKeyEx( HKEY_CURRENT_USER, "$palmman\\$name", 0, KEY_READ, $subkey);
			RegQueryValueEx( $subkey, "Name", [], $t, $d, [] );
			if ( $d eq 'Install' ) {
				RegQueryValueEx( $subkey, "Directory", [], $t, $palminstalldir, [] );
				last;
			}
			RegCloseKey($subkey);
		}
	}
	RegCloseKey($key);

	$self->set_PalmInstallDir( $palminstalldir );
		
	$self->set_UserEntry( Win32::Palm::Install::UsersDat->new( $palmpath . '\users.dat' ) );
}

sub AUTOLOAD {
	no strict 'refs';
	my ($self, $newval) = @_;

	return if $AUTOLOAD =~ /::DESTROY$/;

	# get_ method
	if ($AUTOLOAD =~ /.*::get(_\w+)/ )
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
		return $self->{$attr_name};
	}

	# set_ method
	if ($AUTOLOAD =~ /.*::set(_\w+)/ )
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
		$self->{$attr_name} = $newval;
		return; 
	}
	croak "No such method: $AUTOLOAD";	
}
1;

=head1 VERSION

This document refers to version 0.2 of Win32::Palm::Install, released
25 september 2001.

=head1 SYNOPSIS

	# Install a file

	use Win32::Palm::Install;

	my $file = $ARGV[0];
	my $user = $ARGV[1];

	my $installer = Win32::Palm::Install->new();
	$installer->install( $file, $user );

=head1 DESCRIPTION

This package allows to prepare a palm file for installation.
Just copying the file into the users 'Install' directory does not
work. You have to set a registry flag. If you are curious about which one,
look in the source code.

When you have installed a file, next time the user performs a hotsync,
the file will be transferred to the palm pilot.

=head1 BUGS

It works for me ... please tell me if you observe strange behaviour.

=head1 FILES

	Win32::Palm::Install::UsersDat
	Win32::Palm::Install::UsersDat::UserEntry
	Win32API::Registry
	File::Copy
	File::Basename

=head1 AUTHOR

Johan Van den Brande
<johan@vandenbrande.com>

=head1 COPYRIGHT

Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

