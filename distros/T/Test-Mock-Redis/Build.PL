use strict;
use warnings;
use Module::Build 0.4004;

my $builder = Module::Build->new(
    perl                => '5.006_001',
    module_name         => 'Test::Mock::Redis',
    license             => 'perl',
    dist_author         => q{Jeff Lavallee <jeff@zeroclue.com>},
    dist_abstract       => 'use Redis; without redis',
    dist_version_from   => 'lib/Test/Mock/Redis.pm',
    meta_merge     => {
        resources => {
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Mock-Redis',
            repository => 'http://github.com/jlavallee/Test-Mock-Redis/',
        },
        no_index => { package => [ 'Test::Mock::Redis::PossiblyVolatile',
                                   'Test::Mock::Redis::List',
                                   'Test::Mock::Redis::Hash',
                                   'Test::Mock::Redis::ZSet',
                                   'Test::Mock::Redis::Set',
                                 ],
                    },
    },
    build_requires => {
        'Test::More'        => '0.88',
        'Test::Fatal'       => 0,
        'Test::Deep'        => 0,
        'Test::Deep::UnorderedPairs' => 0,
    },
    requires => {
        'Scalar::Util'      => 0,
        'Class::Method::Modifiers' => 0,
        'Package::Stash'    => '0.34',
        'namespace::clean'  => 0,
        'Try::Tiny'         => 0,
    },
    configure_requires => { 'Module::Build' => 0.4 },
    add_to_cleanup     => [ 'Test-Mock-Redis-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
