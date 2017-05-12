# -*- perl -*-

use Tk::MMutil;
use Tk::Config;
my $l = $Config::Config{'lib_ext'};

warn "This module is for Windows only"
	if $^O !~ /^(MSWin32|cygwin)$/;

Tk::MMutil::TkExtMakefile(
    'NAME'         => 'Tk::WinPrint',
    'INC'          => '',
    'PMLIBDIRS'    => [],
    'OBJECT'       => '$(O_FILES)',
    'VERSION_FROM' => 'WinPrint.pm',
    'XS_VERSION'   => $Tk::Config::VERSION,
    'dist'         => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
   );


