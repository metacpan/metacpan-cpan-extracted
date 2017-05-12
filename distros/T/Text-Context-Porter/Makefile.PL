use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Context::Porter',
    'VERSION_FROM'	=> 'Porter.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Text::Context => 3.3,
        Lingua::Stem::En => 0,
        HTML::Entities => 0,
    }, # e.g., Module::Name => 1.1
);
