use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'PL_FILES' => {},
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'NAME' => 'Unix::SearchPathGuess',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'File::Which' => '1.09',
                                'Test' => 0
                              },
               'VERSION_FROM' => 'lib/Unix/SearchPathGuess.pm',
               'ABSTRACT' => 'Unix::SearchPathGuess -- Make an educated guess for $ENV{\'PATH\'} in a Unixish system',
               'EXE_FILES' => []
             };


WriteMakefile(%$make_args);
