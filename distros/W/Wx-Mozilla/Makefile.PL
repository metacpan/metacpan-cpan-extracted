use strict;
use Wx::build::MakeMaker 0.16;

wxWriteMakefile( NAME         => 'Wx::Mozilla',
                 VERSION_FROM => 'lib/Wx/Mozilla.pm',
                 LIBS         => ( $^O eq 'MSWin32' ? '-lopengl32 -lwxmozilla_gtk2u-2.6' : '-lwxmozilla_gtk2u-2.6' ),
                 WX_CORE_LIB  => 'core base wxmozilla',
               );
