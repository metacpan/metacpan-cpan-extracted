#!/usr/bin/perl

use strict;
use warnings;

use inc::MyBuilder;
use File::Spec::Functions;


my %requires = (
	perl => '5.6.1',

	'Pod::Usage'             => 0,
	'Getopt::Long'           => 0,
	'Glib'                   => 0,
	'Gtk2'                   => '1.100',
	'Time::HiRes'            => 0,
	'XML::LibXML'            => 0,
	'File::Spec::Functions'  => 0,
	'FindBin'                => 0,
	'Carp'                   => 0,
	'Exporter'               => 0,
	'DynaLoader'             => 0,
	'Data::Dumper'           => 0,
	'Gtk2::SourceView2'      => 0,
	'Locale::TextDomain'     => 0,
	'parent'                 => 0,
	'Gtk2::Ex::Entry::Pango' => '0.07',
	'File::BaseDir'          => 0,
);

my %configure_requires = (
	'ExtUtils::Depends'     => 0,
	'ExtUtils::PkgConfig'   => 0,
	'ExtUtils::ParseXS'     => 0,
	'File::Spec::Functions' => 0,
	'File::Path'            => 0,
	'Gtk2'                  => 0,
);

my $build = inc::MyBuilder->new(
	module_name       => 'Xacobeo',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('lib', 'Xacobeo.pm'),

	# Installation files
	script_file => [ catfile('bin', 'xacobeo') ],

	# Dependencies
	requires => \%requires,

	configure_requires => \%configure_requires,

	build_requires => {
		'Test::More'      => 0,
		'File::Slurp'     => 0,
		'Test::Exception' => 0,
		%configure_requires,
	},

	meta_merge => {
		resources => {
			homepage   => 'http://code.google.com/p/xacobeo/',
			bugtracker => 'http://code.google.com/p/xacobeo/issues/list',
			repository => 'http://github.com/potyl/xacobeo',
		},
	},

	add_to_cleanup => [
		catfile ('lib', 'Xacobeo', 'XS.xs'),
		catfile ('lib', 'Xacobeo', 'libxml2-perl.typemap'),
	],
);


$build->create_build_script();

