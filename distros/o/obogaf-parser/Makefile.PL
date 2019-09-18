use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'obogaf::parser',
    VERSION_FROM     => 'lib/obogaf/parser.pm',
    ABSTRACT         => 'a perl5 module to handle obo and gaf file',
    AUTHOR           => 'Marco Notaro',
    LICENSE          => 'Perl_5',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'strict'   => 0,
        'warnings' => 0,
        'Graph'    => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( 
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    web  => 'https://github.com/marconotaro/obogaf-parser',
                    url  => 'git://github.com/marconotaro/obogaf-parser.git',
                },
            },
            keywords => ['parser','obo', 'gaf', 'bio-ontology','annotations'],
        }
    ) : () ),
);