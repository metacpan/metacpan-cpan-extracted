use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

my %elm_pkg_info = ExtUtils::PkgConfig->find('elementary');
my %evas_pkg_info = ExtUtils::PkgConfig->find('evas');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			  => 'pEFL',
	VERSION_FROM	  => 'lib/pEFL.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	CONFIGURE_REQUIRES => {'ExtUtils::PkgConfig' => 0,},
	PREREQ_PM		  => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM	  => 'lib/pEFL.pm', # retrieve abstract from module
	AUTHOR			  => 'Maximilian Lika',
	LICENSE 	   => 'perl',
	#Value must be from legacy list of licenses here
	#http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
	LIBS		  => $elm_pkg_info{'libs'} . $evas_pkg_info{'libs'},
	INC 		  => '-I. ' . $elm_pkg_info{'cflags'} . $evas_pkg_info{'cflags'}, # e.g., '-I. -I/usr/include/other'
	DEFINE			  => '', # e.g., '-DHAVE_SOMETHING'
	XSBUILD => {
	all => {
		LIBS		  => $elm_pkg_info{'libs'} . $evas_pkg_info{'libs'},
		INC 		  => '-Wall -I. ' . $elm_pkg_info{'cflags'} . $evas_pkg_info{'cflags'},
	},
	xs => {
		'lib/pEFL/Ecore/EventHandler' => {
			OBJECT => 'lib/pEFL/Ecore/EventHandler$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Ecore/Evas' => {
			OBJECT => 'lib/pEFL/Ecore/Evas$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Ecore/Timer' => {
			OBJECT => 'lib/pEFL/Ecore/Timer$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Ecore/Idler' => {
			OBJECT => 'lib/pEFL/Ecore/Idler$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Ecore/Poller' => {
			OBJECT => 'lib/pEFL/Ecore/Poller$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Entry' => {
			OBJECT => 'lib/pEFL/Elm/Entry$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Progressbar' => {
			OBJECT => 'lib/pEFL/Elm/Progressbar$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Genlist' => {
			OBJECT => 'lib/pEFL/Elm/Genlist$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/GenlistItemClass' => {
			OBJECT => 'lib/pEFL/Elm/GenlistItemClass$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Layout' => {
			OBJECT => 'lib/pEFL/Elm/Layout$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Menu' => {
			OBJECT => 'lib/pEFL/Elm/Menu$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/NaviframeItem' => {
			OBJECT => 'lib/pEFL/Elm/NaviframeItem$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Hoversel' => {
			OBJECT => 'lib/pEFL/Elm/Hoversel$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Index' => {
			OBJECT => 'lib/pEFL/Elm/Index$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Object' => {
			OBJECT => 'lib/pEFL/Elm/Object$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Slider' => {
			OBJECT => 'lib/pEFL/Elm/Slider$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Ctxpopup' => {
			OBJECT => 'lib/pEFL/Elm/Ctxpopup$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Popup' => {
			OBJECT => 'lib/pEFL/Elm/Popup$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/List' => {
			OBJECT => 'lib/pEFL/Elm/List$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/Toolbar' => {
			OBJECT => 'lib/pEFL/Elm/Toolbar$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/ToolbarItem' => {
			OBJECT => 'lib/pEFL/Elm/ToolbarItem$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Elm/WidgetItem' => {
			OBJECT => 'lib/pEFL/Elm/WidgetItem$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Evas/Object' => {
			OBJECT => 'lib/pEFL/Evas/Object$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/Edje/Object' => {
			OBJECT => 'lib/pEFL/Edje/Object$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
		'lib/pEFL/PLSide' => {
			OBJECT => 'lib/pEFL/PLSide$(OBJ_EXT) PLSide$(OBJ_EXT)',
		},
	},
	},
	XSMULTI => 1,
	META_MERGE => {
		resources => {
			repository => 'https://github.com/MaxPerl/Perl-Efl',
		},
		keywords => [ qw( efl enlightenment Elementary gui) ],
	},
	# OPTIMIZE => '-g',
	# Un-comment this if you add C files to link with later:
	# OBJECT			=> '$(O_FILES)', # link all the C files too
);

require "./CONSTANTS.pl";
