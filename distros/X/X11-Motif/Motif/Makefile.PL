
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$libs = '';
$incs = '';
@defines = ();

if ($want_xbae) {
    push(@defines, '-DWANT_XBAE');

    $libs .= do_L_flag($xbae_lib_dir) . " $xbae_libs ";
    $incs .= do_I_flag($xbae_inc_dir) . " ";
}

if ($want_static_perl) {
    push(@defines, '-DHAVE_TOOLKIT_BOOT');
}

if (defined @defines) {
    push(@extra_MakeMaker_flags, 'DEFINE' => join(' ', @defines));
}

$libs .= join(' ', do_L_flag($motif_lib_dir), do_L_flag($x_lib_dir),
	      $motif_libs, $x_toolkit_libs, $x_libs);

$incs .= join(' ', '-I. -I../Lib -I../Toolkit',
	      do_I_flag($motif_inc_dir), do_I_flag($x_inc_dir));

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::Motif',
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => "Motif.o ../Lib/packages.o ../Toolkit/Toolkit.o XpStack.o XpFolder.o XpLinedArea.o",
	      'VERSION_FROM' => 'Motif.pm',
	      @extra_MakeMaker_flags);
