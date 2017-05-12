use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Wx::Perl::RadioBoxWizardPage',
    AUTHOR              => 'Jouke Visser <jouke@cpan.org>',
    VERSION_FROM        => 'lib\Wx\Perl\RadioBoxWizardPage.pm',
    ABSTRACT_FROM       => 'lib\Wx\Perl\RadioBoxWizardPage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Wx'         => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx-Perl-RadioBoxWizardPage-*' },
);
