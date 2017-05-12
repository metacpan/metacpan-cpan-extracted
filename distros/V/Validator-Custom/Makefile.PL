use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Validator::Custom',
    AUTHOR              => q{Yuki Kimoto <kimoto.yuki@gmail.com>},
    VERSION_FROM        => 'lib/Validator/Custom.pm',
    ABSTRACT_FROM       => 'lib/Validator/Custom.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Object::Simple' => 3.0621
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/Validator-Custom.git',
                web  => 'https://github.com/yuki-kimoto/Validator-Custom',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Validator-Custom-*' },
    test => {TESTS => 't/*.t t/*/*.t'}
);
