use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              =>  'Win32::FileTime',
    'PREREQ_PM'         =>  {
        'Win32::API'        =>  0
    },
    'VERSION_FROM'      =>  'lib/Win32/FileTime.pm'
);