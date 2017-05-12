use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => 'Yahoo::Answers',
    AUTHOR => q{Daniel de O. Mantovani <daniel.oliveira.mantovani@gmail.com>},
    VERSION_FROM  => 'lib/Yahoo/Answers.pm',
    ABSTRACT_FROM => 'lib/Yahoo/Answers.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                     => 0,
        'Moose'                          => 0,
        'Moose::Util::TypeConstraints'   => 0,
        'MooseX::Types::Common::String'  => 0,
        'MooseX::Types::Common::Numeric' => 0,
        'WWW::Mechanize'                 => 0,
        'URI::QueryParam'                => 0,
        'JSON'                           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Yahoo-Answers-*' },
);
