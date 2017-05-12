use 5.005;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::CSV::R',
    license             => 'perl',
    dist_author         => '<limaone@cpan.org>',
    dist_version_from   => 'lib/Text/CSV/R.pm',
    requires => {
        'perl'           => '5.6.0', 
        'Scalar::Util'   => 0,
        'List::Util'     => 0,
        'Carp'           => 0,
        'Text::CSV'      => 1,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'Test::LongString' => 0,
        'File::Temp'       => 0,
    }, 
    meta_merge => {
        resources => {
            repository => 'http://github.com/lima1/p5-text-csv-r',
        },
    },
    add_to_cleanup      => [ 'Text-CSV-R-*' ],
);

$builder->create_build_script();
