
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$libs = '';
$incs = '';

$libs .= join(' ', do_L_flag($athena_lib_dir), do_L_flag($x_lib_dir),
	      $athena_libs, $x_toolkit_libs, $x_libs);

$incs .= join(' ', '-I. -I../Lib -I../Toolkit',
	      do_I_flag($athena_inc_dir), do_I_flag($x_inc_dir));

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::Athena',
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => "Athena.o ../Lib/packages.o ../Toolkit/Toolkit.o",
	      'VERSION_FROM' => 'Athena.pm',
	      @extra_MakeMaker_flags);
