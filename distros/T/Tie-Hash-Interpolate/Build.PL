use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Hash::Interpolate',
    license             => 'perl',
    dist_author         => q{Dan Boorstein <danboo@cpan.org>},
    dist_version_from   => 'lib/Tie/Hash/Interpolate.pm',
    build_requires => {
        'Test::More'   => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Tie-Hash-Interpolate-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge          =>
       {
       resources =>
          {
          repository  => 'http://github.com/danboo/perl-tie-hash-interpolate/',
          }
       },
);

$builder->create_build_script();
