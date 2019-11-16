use 5.006;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'obogaf::parser',
    VERSION_FROM     => 'lib/obogaf/parser.pm',
    ABSTRACT         => 'a perl5 module to handle obo and gaf file',
    AUTHOR           => 'Marco Notaro',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    PREREQ_PM        => {
        'Graph'             => 0,
        'PerlIO::gzip'      => 0
    },
    TEST_REQUIRES  => {
        'Test::More'            => 0, 
        'Test::Exception'       => 0,
        'Test::Files'           => 0
    },
    CONFIGURE_REQUIRES  => {
        'Module::Metadata'      => 0,
        'ExtUtils::MakeMaker'   => 0
    },
    META_ADD         => {
        provides  => Module::Metadata->provides(version => '2', dir => 'lib'),
    },
    clean   => {
        FILES   => "t/data/test_gobasic_no_namespace.obo
                    t/data/test_gobasic_edges.txt
                    t/data/test_gobasic_edges_no_namespace.txt
                    t/data/test_gobasic_edgesBP.txt
                    t/data/test_gobasic_edges_header.txt
                    t/data/test_gobasic_edges_stat.txt
                    t/data/test_chicken.uniprot2go.txt
                    t/data/test_goa_chicken_header.gaf
                    t/data/test_chicken_uniprot2go_header.txt
                    t/data/test_chicken_goa_mapped.txt
                    t/data/test_goa_chicken_128_header.gaf
                    t/data/test_chicken_goa_mapped_header.txt
                    t/data/test_goa_chicken_128_unpair.gaf
                    t/data/test_chicken_goa_mapped_unpair.txt
                    t/data/test_gobasic_parents_list.txt
                    t/data/test_gobasic_children_list.txt
                    t/data/test_gobasicBP_parents_list.txt
                    t/data/test_gobasicBP_children_list.txt"
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( 
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {                    
                    type      => 'git',
                    web       => 'https://github.com/marconotaro/obogaf-parser',
                    url       => 'git://github.com/marconotaro/obogaf-parser.git',
                },
            },
            keywords => ['parser', 'obo', 'gaf', 'bio-ontology', 'annotations'],
        }
    ) : () ),
);
