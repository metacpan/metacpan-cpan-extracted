use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Tie::Locked',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Tie::Locked -- lock hashes so that they cannot be easily changed',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Tie/Locked.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {}
             };


WriteMakefile(%$make_args);
