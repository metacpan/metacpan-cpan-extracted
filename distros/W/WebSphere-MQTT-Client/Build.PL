#!/usr/bin/perl
#

use Module::Build;
use English;
use strict;


# Threading is disabled for the time being
my $CFLAGS = '-DMSP_SINGLE_THREAD';
my $LDFLAGS = '';


# Work out flags for different OSes
# or use Module::Build::os_type() ?
if ($OSNAME eq 'darwin') {
	# Mac OS X
	$CFLAGS .= ' -DUNIX -Wall';
} elsif ($OSNAME eq 'linux') {
	$CFLAGS .= ' -DUNIX -DLINUX -Wall';
} elsif ($OSNAME eq 'aix') {
	$CFLAGS .= ' -DUNIX -DAIX';
} elsif ($OSNAME eq 'sunos') {
	$CFLAGS .= ' -DUNIX -DSOLARIS';
} elsif ($OSNAME eq 'hpux') {
	$CFLAGS .= ' -DUNIX -DHPUX -D_HPUX_SOURCE';
} elsif ($OSNAME eq 'win32') {
	$CFLAGS .= ' -DWIN32';
} else {
	# Assume UNIX
	print "Unsuppored OS '$OSNAME'. Assuming Unix.\n";
	$CFLAGS .= ' -DUNIX';
}



# Create the Build script
my $build = Module::Build->new
(
	module_name => 'WebSphere::MQTT::Client',
	license => 'restrictive',
	script_files => [
		'examples/subscribe.pl',
		'examples/publish.pl',
	],
	build_requires => {
		'Module::Build' => '0.20'
	},
	requires => {
		'Test' => '1.00',
		'Getopt::Std' => 0,
		'Pod::Usage' => 0,
		'Data::Dumper' => 0,
		'Time::HiRes' => 0,
	},
	
	
	create_makefile_pl => 'passthrough',
	
	include_dirs => [ 'src' ],
	c_source => 'src',
	extra_compiler_flags => $CFLAGS,
	extra_linker_flags => $LDFLAGS,
);

$build->create_build_script;
