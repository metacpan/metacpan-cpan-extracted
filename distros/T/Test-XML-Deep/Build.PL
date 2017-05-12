use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::XML::Deep',
    license             => 'perl',
    dist_author         => 'Jeff Lavallee <jeff@zeroclue.com>',
    dist_abstract       => 'XML::Simple + Test::Deep = Test::XML::Deep',
    dist_version_from   => 'lib/Test/XML/Deep.pm',
    meta_merge     => {
        resources => {
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-XML-Deep',
            repository => 'http://github.com/jlavallee/test-xml-deep/tree/master',
        }
    },
    sign                => 1,
    build_requires => {
        'Test::Simple' => 0.86,
        'Test::NoWarnings' => 0,
    },
    requires => {
        'perl'        => 5.006,
        'XML::Parser' => 2.36,
        'XML::Simple' => 2.18,
        'Test::Deep'  => 0.104,
    },
    add_to_cleanup      => [ 'Test-XML-Deep-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
