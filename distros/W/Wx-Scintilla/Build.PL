use 5.006;
use strict;

use lib 'inc';
require Module::Build::Scintilla;

# Create build script
Module::Build::Scintilla::stc_builderclass()->new(
	module_name        => 'Wx::Scintilla',
	license            => 'perl',
	dist_author        => q{Ahmad M. Zawawi <ahmad.zawawi@gmail.com>},
	dist_version_from  => 'lib/Wx/Scintilla.pm',
	configure_requires => {
		'perl'          => '5.006',
		'Module::Build' => '0.36',
	},
	build_requires => {
		'Test::More'       => 0,
		'Alien::wxWidgets' => 0,
		'Wx'               => 0,
		'ExtUtils::XSpp'   => '0.1602',
	},
	requires => {
		'perl' => '5.008',
	},
	needs_compiler => 0, # We will be doing our own XS compilation
	add_to_cleanup => [
		'Wx-Scintilla-*',
		'wx-scintilla/src/*.o.d',
		'wx-scintilla/src/*.o',
		'wx-scintilla/src/*.obj',
		'wx-scintilla/src/scintilla/src/*.o.d',
		'wx-scintilla/src/scintilla/src/*.o',
		'wx-scintilla/src/scintilla/src/*.obj',
		'Scintilla.c',
		'Scintilla.o',
		'Scintilla.obj',
		'Scintilla.bs',
		'Scintilla.def',
		'Scintilla_def.old',
		'blib',
		'*.dll',
		'*.pdb',
		'*.obj',
		'*.a',
		'*.so',
		'stc_checkdepends.out',
	],
	meta_merge => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Wx-Scintilla/',
		},
		no_index => {
			directory => [qw<tools wx-scintilla cpp inc>],
		},
	},
	dist_abstract      => 'Scintilla source code editing for wxWidgets',
	extra_linker_flags => '-lwxmsw28u_scintilla',
)->create_build_script();
