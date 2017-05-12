use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Search::MSN',
    license             => 'mit',
    dist_author         => 'Shlomi Fish',
    dist_version_from   => 'lib/WWW/Search/MSN.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'perl' => '5.008',
        'Encode' => 0,
        'HTML::TreeBuilder' => 0,
        'Scalar::Util' => 0,
        'Test::More' => 0,
        'WWW::Search' => 2.523,
        'WWW::Search::Test' => 2.265,
    },
    add_to_cleanup      => [ 'WWW-Search-MSN-*' ],
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => 'http://bitbucket.org/shlomif/www-search-backends',
        },
    },
);

$builder->create_build_script();
