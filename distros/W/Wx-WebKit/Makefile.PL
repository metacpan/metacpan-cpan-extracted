use strict;
use Wx::build::MakeMaker 0.16;

if ($^O ne 'darwin') {
    die "Webkit's only on OS X";
}

wxWriteMakefile( NAME         => 'Wx::WebKit',
                 VERSION_FROM => 'lib/Wx/WebKit.pm',
                 LIBS         => '',
                 WX_CORE_LIB  => 'core base webkit',
               );
