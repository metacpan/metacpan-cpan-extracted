require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Test::Most',
    'VERSION_FROM' => 'lib/Test/Most.pm',
    'PREREQ_PM'    => {
        'Exception::Class'  => '1.14',
        'Test::Deep'        => '0.119',
        'Test::Differences' => '0.64',
        'Test::Exception'   => '0.43',
        'Test::Harness'     => '3.35',
        'Test::More'        => '1.302047',
        'Test::Warn'        => '0.30'
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    META_MERGE    => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:Ovid/test--most.github',
                web  => 'https://github.com/Ovid/test--most',
            },
        },
    },
);
