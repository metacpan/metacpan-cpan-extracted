use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Win32::OLE::CrystalRuntime::Application',
    VERSION_FROM => 'lib/Win32/OLE/CrystalRuntime/Application.pm',
    AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
    ABSTRACT_FROM=> 'lib/Win32/OLE/CrystalRuntime/Application.pm',
    LICENSE      => 'bsd',
    PREREQ_PM    => {
                     'Test::Simple'        => 0.44,
                     'strict'              => 0,
                     'vars'                => 0,
                     'constant'            => 0,
                     'Win32::OLE'          => 0,
                     'Win32::OLE::Variant' => 0,
                     'DateTime'            => 0,
                    },
            dist => {DIST_DEFAULT => 'zipdist'},

);
