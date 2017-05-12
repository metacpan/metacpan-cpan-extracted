
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$libs = join(' ', do_L_flag($x_lib_dir), $x_toolkit_libs, $x_libs);
$incs = join(' ', '-I. -I../Lib', do_I_flag($x_inc_dir));
@defines = ();

if ($has_fast_quarks) {
    push(@defines, '-DHAS_FAST_QUARKS');
}

if (defined @defines) {
    push(@extra_MakeMaker_flags, 'DEFINE' => join(' ', @defines));
}

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::Toolkit',
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => 'Toolkit.o ../Lib/packages.o',
	      'VERSION_FROM' => 'Toolkit.pm',
	      @extra_MakeMaker_flags);
