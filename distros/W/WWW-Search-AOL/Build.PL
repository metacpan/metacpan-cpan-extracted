use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Search::AOL',
    license             => 'mit',
    dist_author         => 'Shlomi Fish',
    dist_version_from   => 'lib/WWW/Search/AOL.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => '5.008',
        'Test::More' => 0,
        'WWW::Search' => 2.565,
        'WWW::Search::Test' => 2.287,
        'HTML::TreeBuilder' => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'WWW-Search-AOL-*' ],
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
