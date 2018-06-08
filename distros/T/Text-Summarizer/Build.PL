use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Summarizer',
    license             => 'perl',
    dist_author         => 'Faelin Landy <faelin.landy@gmail.com>',
    dist_version_from   => 'lib/Text/Summarizer.pm',
    dist_abstract	    => 'Extract repeated phrases from text',
    build_requires => {
    },
    requires => {
        'Moo'                 => 0,
        'Types::Standard'     => 0,
        'List::AllUtils'      => 0,
        'Algorithm::CurveFit' => 0,
        'Lingua::Stem'        => 0,

    },
    add_to_cleanup      => [ 'Text::Summarizer-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'https://github.com/faelin/text-summarizer/'
        },
    },
    configure_requires => { 'Module::Build' => 2.01 }
);

$builder->create_build_script();
print "Have a great day!\n";