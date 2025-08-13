use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Text::PrettyTable',
    VERSION_FROM      => 'lib/Text/PrettyTable.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Text/PrettyTable.pm',
    AUTHOR            => 'Rob Brown <bbb@cpan.org>',
    LICENSE           => 'artistic',
);
