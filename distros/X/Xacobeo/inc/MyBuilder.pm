#!/usr/bin/perl

package inc::MyBuilder;


use strict;
use warnings;

BEGIN {

	foreach my $module (qw(ExtUtils::Depends ExtUtils::PkgConfig ExtUtils::ParseXS)) {
		eval "use $module";
		if (my $error = $@) {
			warn "Missing build dependency $module.";
			warn $error;
		}
	}
}


use base 'Module::Build';
use File::Spec::Functions;
use File::Path;

my $CFLAGS;
my $LIBS;
my $TYPEMAPS;
my $C_FILE;
my $XS_FILE;


BEGIN {
	# Automatically find the dependencies
	my $package = ExtUtils::Depends->new('Xacobeo::XS', 'Gtk2');
	$package->add_typemaps('libxml2-perl.typemap');
	my %config = $package->get_makefile_vars();

	# Add manually the libraries that don't provide typemaps
	my %libxml = ExtUtils::PkgConfig->find('libxml-2.0');
	$CFLAGS   = "-g -std=c99 $config{INC} $libxml{cflags}";
	$LIBS     = "$config{LIBS} $libxml{libs}";
	$TYPEMAPS = $config{TYPEMAPS};

	# Make sure that the XS-C file doesn't exist otherwise it will be linked twice 
	$C_FILE = catfile('lib', 'Xacobeo', 'XS.c');
	unlink($C_FILE);
	$XS_FILE = catfile('lib', 'Xacobeo', 'XS.xs');
}


sub new {
	my $class = shift;
	my (%args) = @_;
	
	$args{extra_compiler_flags} = $CFLAGS;
	$args{extra_linker_flags}   = $LIBS;
	$args{c_source} = 'xs';
	
	$class->SUPER::new(%args);
}


sub ACTION_install {
	my $self = shift;

	# If we have more than one install base then take the last entry, otherwise
	# we will install the application in ARRAY(0x1c577f8)/
	my $install_base = $self->install_base;
	$self->install_base($install_base->[-1]) if ref $install_base eq 'ARRAY';

	# Make sure that 'share/' has an installation path
	my $p = $self->{properties};
	if (! exists $p->{install_path}{share}) {
		my $script_dir = $self->install_destination('script');
		my @dirs = File::Spec->splitdir($script_dir);
		$dirs[-1] = 'share';
		$p->{install_path}{share} = File::Spec->catdir(@dirs);
	}

	# Proceed normally
	$self->SUPER::ACTION_install(@_);
}


sub ACTION_post_install {
	my $self = shift;
	print "Updating desktop database\n";
	system('update-desktop-database');
}


sub ACTION_build {
	my $self = shift;

	# Copy the files in share/
	foreach my $entry (@{ $self->rscan_dir('share') }) {

		# Skip hidden entries or folders
		next if $entry =~ m,(^|/)\., or -d $entry;

		$self->copy_if_modified(
			from => $entry,
			to   => catfile($self->blib, $entry) 
		);
	}

	# Translate the PO files into .mo files
	foreach my $entry (@{ $self->rscan_dir('po') }) {
		next unless $entry =~ /([a-zA-Z_]+)\.po$/;
		my $lang = $1;
		
		# The .mo files go into their own folder, each language has it's own folder
		my $dir = catdir($self->blib, 'share', 'locale', $lang, 'LC_MESSAGES');
		mkpath($dir);
		my $mo_file = catfile($dir, 'xacobeo.mo');
		print "Translating $entry -> $mo_file\n";
		system('msgfmt', '-o', $mo_file, $entry);
	}

	# Copy the XS.xs and the typemap file to the lib folder. This way 
	# Module::Build will handle the compilation and installation of the XS
	# library.
	foreach my $file ('XS.xs', 'libxml2-perl.typemap') {
		$self->copy_if_modified(
			from => catfile('xs', $file),
			to   => catfile('lib', 'Xacobeo', $file),
		);
	}

	# Proceed normally
	$self->SUPER::ACTION_build(@_);
}


# Transform the XS into a C file to our liking
sub process_xs_files {
	my $self = shift;

	ExtUtils::ParseXS::process_file(
		filename   => $XS_FILE,
		prototypes => 0,
		typemap    => $TYPEMAPS,
		output     => $C_FILE,
	);
	
	# Proceed normally
	$self->SUPER::process_xs_files(@_);
}


# Return a true value
1;
