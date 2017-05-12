use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'ABSTRACT' => 'Test::Toolbox - tools for testing',
               'PREREQ_PM' => {},
               'LICENSE' => 'perl',
               'PL_FILES' => {},
               'VERSION_FROM' => 'lib/Test/Toolbox.pm',
               'NAME' => 'Test::Toolbox',
               'EXE_FILES' => [],
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>'
             };


WriteMakefile(%$make_args);
