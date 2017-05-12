use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'WSDL::Compile',
    license           => 'perl',
    dist_author       => q{Alex J. G. Burzyński <ajgb@cpan.org>},
    dist_version_from => 'lib/WSDL/Compile.pm',
    build_requires    => {
        'Test::More'               => 0,
        'Test::Differences'        => 0,
        'Test::NoWarnings'         => 0,
        'Data::Dumper'             => 0,
        'Moose'                    => '0.93',
        'MooseX::Types::XMLSchema' => 0.02,
        'MooseX::Params::Validate' => '0.12',
        'List::Util'               => '1.21',
        'Perl6::Junction'          => '1.40000',
        'XML::LibXML'              => '1.69',
    },
    add_to_cleanup     => ['WSDL-Compile-*'],
    create_makefile_pl => 'passthrough',
    create_readme      => 0, # Pod::Parser doesn't support =encoding
    create_licence     => 1,
);

$builder->create_build_script();
