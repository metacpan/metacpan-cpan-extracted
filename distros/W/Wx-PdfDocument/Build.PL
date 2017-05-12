use 5.008;
use strict;

use lib 'inc';
require Module::Build::PdfDocument;

our $VERSION = '0.13';

# Create build script
my $build = Module::Build::PdfDocument::wxpdf_builderclass()->new(
	module_name        => 'Wx::PdfDocument',
	license            => 'perl',
	dist_author        => q{Mark Wardell <mwardell@cpan.org>},
	dist_version_from  => 'lib/Wx/PdfDocument.pm',
	configure_requires => {
		'perl'          => '5.008',
		'Module::Build' => '0.36',
	},
	build_requires => {
        'Archive::Extract' => 0,
        'LWP::UserAgent'   => 0,
        'LWP::Protocol::https'   => 0,
		'Test::More'       => 0,
		'ExtUtils::XSpp'   => '0.1602',
        'Text::Patch'      => '1.8',
	},
	requires => {
		'perl'             => '5.008',
        'Alien::wxWidgets' => '0.27',
		'Wx'               => '0.9909',
        'Class::Accessor'  => '0.34',
	},
	needs_compiler => 0, # We will be doing our own XS compilation
	add_to_cleanup => [
		'PdfDocument.c',
		'PdfDocument.o',
		'PdfDocument.obj',
		'PdfDocument.bs',
		'PdfDocument.def',
		'PdfDocument_def.old',
		'blib',
		'*.dll',
		'*.pdb',
		'*.obj',
		'*.a',
		'*.so',
        Module::Build::PdfDocument::wxpdf_libdirectory(),
        'cpp/ovl_const.h',
        'cpp/ovl_const.cpp',
        'pdfbsuccess.scs',
	],
	meta_merge => {
		resources => {
			homepage   => 'http://code.google.com/p/wxperl-pdfdocument/wiki/Home',
			repository => 'http://wxperl-pdfdocument.googlecode.com/svn/',
		},
		no_index => {
			directory => [qw<src cpp inc myinc msw patches demo>],
		},
	},
	dist_abstract      => 'PDF output for wxWidgets',
    
    get_options        => {
        'pdfdoc-build-target' => { type => '=s', default => 'perl' },
    },

);

$build->notes( 'pdfdoc-build-target' => $build->args('pdfdoc-build-target') );

$build->create_build_script();

1;

