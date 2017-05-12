use strict;
use warnings;

use lib 'inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Text::Sprintf::Named',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Text/Sprintf/Named.pm',
    requires => {
        'Carp' => 0,
        'Exporter' => 0,
        'parent' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
        'warnings::register' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Warn' => '0.21',
    },
    add_to_cleanup      => [ 'Text::Sprintf::Named-*' ],
    configure_requires => {
        'Module::Build' => '0.36',
    },
    meta_merge => {
        resources => {
            repository => "https://bitbucket.org/shlomif/perl-text-sprintf",
        },
        keywords =>
        [
            "conversions",
            "format",
            "named",
            "percent",
            "python",
            "sprintf",
        ],
    },
);

$builder->create_build_script();
