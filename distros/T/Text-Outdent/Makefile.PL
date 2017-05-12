use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Outdent',
    VERSION_FROM => 'lib/Text/Outdent.pm', # finds $VERSION
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Text::Outdent',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
