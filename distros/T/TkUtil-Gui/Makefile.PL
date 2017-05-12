use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TkUtil::Gui',
    AUTHOR              => 'X Cramps <cramps.the@gmail.com>',
    VERSION_FROM        => 'lib/TkUtil/Gui.pm',
    ABSTRACT_FROM       => 'lib/TkUtil/Gui.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perl6::Attributes' => '0.04',
        'Tk' => '804.025',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TkUtil-Gui-*' },
);
