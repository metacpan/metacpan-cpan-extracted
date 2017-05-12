use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'PL_FILES' => {},
               'VERSION_FROM' => 'lib/Unix/Mgt.pm',
               'NAME' => 'Unix::Mgt',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'String::Util' => '1.24',
                                'IPC::System::Simple' => '1.25',
                                'Unix::SearchPathGuess' => '0.11',
                                'JSON::Tiny' => '0.50',
                                'Capture::Tiny' => '0.25'
                              },
               'EXE_FILES' => [],
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Unix::Mgt - lightweight Unix management tools'
             };


WriteMakefile(%$make_args);
