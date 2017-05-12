
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$libs = join(' ', do_L_flag($xpm_lib_dir), do_L_flag($x_lib_dir), $xpm_libs, $x_libs);

$incs = join(' ', '-I. -I../Lib', do_I_flag($xpm_inc_dir), do_I_flag($x_inc_dir));

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::Xpm',
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => 'Xpm.o ../Lib/packages.o',
	      'VERSION_FROM' => 'Xpm.pm',
	      @extra_MakeMaker_flags);
