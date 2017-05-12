use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Text::Extract::MaketextCallPhrases',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Text/Extract/MaketextCallPhrases.pm',
    ABSTRACT_FROM => 'lib/Text/Extract/MaketextCallPhrases.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'File::Temp' => 0,

        'Text::Balanced'      => 0,
        'String::Unquotemeta' => 0,
        'Module::Want'        => '0.6',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Text-Extract-MaketextCallPhrases-*' },
);
