use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Win32::FileSystem::Watcher',
    'VERSION_FROM' => 'lib/Win32/FileSystem/Watcher.pm',
    'PREREQ_PM'    => {
        'Win32::MMF::Shareable' => 0,
        'Win32::API'            => 0,
        'Win32'                 => 0,
        'Test::Exception'       => 0,
        'Scalar::Util'          => 0,
        'Carp'                  => 0,
    },
    'LIBS'    => [],
    'DEFINE'  => '',
    'INC'     => '',
    'LICENSE' => 'perl',
);
