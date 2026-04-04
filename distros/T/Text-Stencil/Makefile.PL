use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Text::Stencil',
    VERSION_FROM  => 'lib/Text/Stencil.pm',
    ABSTRACT      => 'Fast XS list/table renderer with escaping, formatting, and transform chaining',
    AUTHOR        => 'vividsnow',
    XS            => { 'XS.xs' => 'XS.c' },
    OBJECT        => 'XS$(OBJ_EXT)',
    OPTIMIZE      => '-O3',
    MIN_PERL_VERSION => '5.020',
    LICENSE       => 'perl_5',
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-text-stencil.git',
                web  => 'https://github.com/vividsnow/perl5-text-stencil',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-text-stencil/issues',
            },
        },
    },
);
