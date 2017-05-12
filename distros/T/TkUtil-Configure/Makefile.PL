use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TkUtil::Configure',
    AUTHOR              => 'X Cramps <cramps.the@gmail.com>',
    VERSION_FROM        => 'lib/TkUtil/Configure.pm',
    ABSTRACT_FROM       => 'lib/TkUtil/Configure.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perl6::Attributes' => '0.04',
        'Time::HiRes' => '1.9711',
        'Tk' => '804.025',
    },
    #dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', TARFLAGS =>'cvzf --numeric-owner'},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TkUtil-Configure-*' },
);
