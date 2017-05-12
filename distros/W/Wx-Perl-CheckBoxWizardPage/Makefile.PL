use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Wx::Perl::CheckBoxWizardPage',
    AUTHOR              => 'Jouke Visser <jouke@pvoice.org>',
    VERSION_FROM        => 'lib\Wx\Perl\CheckBoxWizardPage.pm',
    ABSTRACT_FROM       => 'lib\Wx\Perl\CheckBoxWizardPage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Wx'         => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx-Perl-CheckBoxWizardPage-*' },
);
