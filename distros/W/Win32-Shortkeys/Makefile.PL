

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Win32::Shortkeys',
    VERSION_FROM => 'lib/Win32/Shortkeys.pm', # finds \$VERSION
    AUTHOR       => 'FranE<ccedil>ois Rappaz (rappazf@gmail.com)',
    ABSTRACT     => 'Shortkeys for windows',
    PREREQ_PM    => {
                     'Win32::Shortkeys::Kbh' => 0.01,                  
                     'Test::Simple' => 0.44,
                     'Config::YAML::Tiny' => 1.42.0,
                     'Win32::Clipboard' => 0.58,
                     'XML::Parser' => 2.44,
                     'Encode' => 2.84,
                     'Time::HiRes' => 1.9733,
                     'Carp' => 1.40
                    },
);

