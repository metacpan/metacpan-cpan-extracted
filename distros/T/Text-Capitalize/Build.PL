use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Capitalize',
    license             => 'perl',
    dist_author         => q{Joseph Brenner <doom@kzsu.stanford.edu>},
    dist_version_from   => 'lib/Text/Capitalize.pm',
    build_requires => {
                       'Test::More'     => 0,
                       'FindBin'        => 1.04,
                       'lib'            => 0,
                       'Env'            => 1.00,
                       'Data::Dumper'   => 0,
                       'PerlIO::locale' => 0,
                      },
    build => {
              'strict'   => 0,
              'warnings' => 0,
              'utf8'     => 0,
              'Carp'     => 0,
              'Exporter' => 0,
              'vars'     => 0,
             },
    add_to_cleanup      => [ 'Text-Capitalize-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
