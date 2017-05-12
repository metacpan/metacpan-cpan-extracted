use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 're::engine::Lua',
    AUTHOR        => 'Francois PERRAD <francois.perrad@gadz.org>',
    VERSION_FROM  => 'Lua.pm',
    ABSTRACT_FROM => 'Lua.pm',
    LICENSE       => 'MIT',
    PREREQ_PM     => {
        'XSLoader'        => 0,
    },
    MIN_PERL_VERSION => 5.010,
);
