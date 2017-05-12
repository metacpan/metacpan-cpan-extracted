use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Wx::Perl::HtmlWizardPage',
    AUTHOR              => 'Jouke Visser <jouke@pvoice.org>',
    VERSION_FROM        => 'lib\Wx\Perl\HtmlWizardPage.pm',
    ABSTRACT_FROM       => 'lib\Wx\Perl\HtmlWizardPage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Wx'         => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx-Perl-HtmlWizardPage-*' },
);
