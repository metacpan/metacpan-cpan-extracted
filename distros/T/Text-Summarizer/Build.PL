use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Summarizer',
    license             => 'perl',
    dist_author         => 'Faelin Landy <faelin.landy@gmail.com>',
    dist_version_from   => 'lib/Text/Summarizer.pm',
    dist_abstract	    => 'Extract Repeated Phrases from Text',
    build_requires => {
        'Test::More'   => 0,
        'Data::Dumper' => 0,
        'Carp'         => 0,
    },
    requires => {
        'Lingua::Sentence'  => '1.100',
        'Moo'               => '2.003002',
        'Types::Standard'   => 0,
        'List::AllUtils'    => 0,
        'Data::Dumper'      => 0,
    },
    add_to_cleanup      => [ 'Text::Summarizer-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'https://github.com/faelin/text-summarizer/tree/master'
        },
    },
    configure_requires => { 'Module::Build' => 0.42 }
);

$builder->create_build_script();
print "Have a great day!\n";