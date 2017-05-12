use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'YAPE::Regex',
    'VERSION_FROM' => 'Regex.pm', # finds $VERSION
    'PREREQ_PM' => {
        'Text::Balanced' => 0,
    },
);
