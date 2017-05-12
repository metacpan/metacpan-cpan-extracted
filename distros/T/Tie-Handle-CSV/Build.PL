use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Handle::CSV',
    license             => 'perl',
    dist_author         => 'Daniel B. Boorstein <danboo@cpan.org>',
    dist_version_from   => 'lib/Tie/Handle/CSV.pm',
    build_requires => {
        'Test::More' => 0,
        'Text::CSV_XS' => 0,
    },
    add_to_cleanup      => [ 'Tie-Handle-CSV-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge          =>
       {
       resources =>
          {
          repository  => 'http://github.com/danboo/perl-tie-handle-csv/',
          }
       },
);

$builder->create_build_script();
