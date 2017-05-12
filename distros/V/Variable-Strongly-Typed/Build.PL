use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Variable::Strongly::Typed',
    license             => 'perl',
    dist_author         => 'Mark Ethan Trostler <mark@zzo.com>',
    dist_version_from   => 'lib/Variable/Strongly/Typed.pm',
    requires => {
        'Test::More'            => 0,
        'version'               => 0,
        'Class::Std::Utils'     => 0,
        'Attribute::Handlers'   => 0,
        'Tie::Hash'             => 0,
        'Tie::Array'            => 0,
        'Tie::Scalar'           => 0,
        'IO::File'              => 0,

    },
    add_to_cleanup      => [ 'Variable-Strongly-Typed-*' ],
);

$builder->create_build_script();
