use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Win32::IPConfig',
    'VERSION_FROM'  => 'lib/Win32/IPConfig.pm',
    'PREREQ_PM'     => {
        'Win32::TieRegistry' => 0,
    },
    'ABSTRACT_FROM' => 'lib/Win32/IPConfig.pm',
    'AUTHOR'        => 'James Macfarlane',
    ($ExtUtils::MakeMaker::VERSION > 6.30 ? (LICENSE => 'perl') : ()),
);
