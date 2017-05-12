
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$libs = join(' ', do_L_flag($x_lib_dir), $x_libs);

$incs = join(' ', '-I.', do_I_flag($x_inc_dir));

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::Lib',
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => 'Lib.o packages.o',
	      'VERSION_FROM' => 'Lib.pm',
	      @extra_MakeMaker_flags);
