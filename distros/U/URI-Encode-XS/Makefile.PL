use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'URI::Encode::XS',
    VERSION_FROM   => 'lib/URI/Encode/XS.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/URI/Encode/XS.pm',
    AUTHOR         => 'David Farrell',
    LIBS           => [''],
    OPTIMIZE       => '-O3',
    DEFINE         => '',
    INC            => '-I.',
    LICENSE        => 'freebsd',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dnmfarrell/URI-Encode-XS.git',
                web  => 'https://github.com/dnmfarrell/URI-Encode-XS',
            },
        }})
     : ()
    ),
);
