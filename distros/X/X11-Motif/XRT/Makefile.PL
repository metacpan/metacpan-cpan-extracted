
# Copyright 1997, 1998 by Ken Fox

use Config;
use ExtUtils::MakeMaker;
require "../config.pm";
do_reset_flags();

$xrt_libs = '';
$xrt_flags = '';

if ($want_xrt_table) {
    $xrt_libs .= ' -lxrttable';
    $xrt_flags .= ' -DWANT_XRT_TABLE';
}

if ($want_xrt_graph) {
    $xrt_libs .= ' -lxrtm';
    $xrt_flags .= ' -DWANT_XRT_GRAPH';
}

if ($want_xrt_3d) {
    $xrt_libs .= ' -lxrt3d';
    $xrt_flags .= ' -DWANT_XRT_3D';
}

if ($want_xrt_gear) {
    $xrt_libs .= ' -lxrtgear';
    $xrt_flags .= ' -DWANT_XRT_GEAR';
}

if ($want_xrt_field) {
    $xrt_libs .= ' -lxrtfield';
    $xrt_flags .= ' -DWANT_XRT_FIELD';
}

$libs = join(' ', do_L_flag($xrt_lib_dir), do_L_flag($motif_lib_dir),
	     do_L_flag($x_lib_dir), $xrt_libs, $motif_libs, $x_toolkit_libs, $x_libs);

$incs = join(' ', '-I. -I../Lib -I../Toolkit -I../Motif',
	     do_I_flag($xrt_inc_dir), do_I_flag($motif_inc_dir), do_I_flag($x_inc_dir));

sub MY::postamble {'
XRT.pm: XRT.in
	'.join(' ', $Config{'cppstdin'}, $xrt_flags, $incs, $Config{'cppminus'}).' < XRT.in > XRT.pm
'}

WriteMakefile('OPTIMIZE' => '-g',
	      'TYPEMAPS' => [ '../typemap' ],
	      'NAME' => 'X11::XRT',
	      'PM' => { 'XRT.pm' => '$(INST_LIBDIR)/XRT.pm',
			'XRTCons.pm' => '$(INST_LIBDIR)/XRTCons.pm' },
	      'realclean' => { FILES => 'XRT.pm' },
	      'DEFINE' => $xrt_flags,
	      'INC' => $incs,
	      'LIBS' => [ $libs ],
	      'OBJECT' => "XRT.o ../Lib/packages.o ../Toolkit/Toolkit.o ../Motif/Motif.o",
	      'VERSION_FROM' => 'XRT.in',
	      @extra_MakeMaker_flags);
