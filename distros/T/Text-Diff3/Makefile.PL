use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Text::Diff3',
    VERSION_FROM      => 'lib/Text/Diff3.pm',
    PREREQ_PM         => {
        'Test::Base' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Text/Diff3.pm',
       AUTHOR         => 'MIZUTANI Tociyuki <tociyuki@gmail.com>') : ()),
);
