use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::FuncNet::Predictor',
    license             => 'perl',
    dist_author         => 'Ian Sillitoe <sillitoe@biochem.ucl.ac.uk>',
    dist_version_from   => 'lib/WebService/FuncNet/Predictor.pm',
    requires => {
        "Test::More"                        => '0.77',
        "Data::Dumper"                      => 0,
        "File::Temp"                        => '0.21',
        "LWP::UserAgent"                    => '5.822',
        "Log::Log4perl"                     => '1.20',
        "Moose"                             => '0.64',
        "MooseX::Types"                     => '0.08',
        "Readonly"                          => '1.03',
        "URI"                               => '1.37',
        "URI::Heuristic"                    => '4.18',
        "URI::file"                         => '4.20',
        "XML::Compile::Schema"              => '1.05',
        "XML::Compile::Transport::SOAPHTTP" => '2.04',
        "XML::Compile::WSDL11"              => '2.04',
    },
    add_to_cleanup      => [ 'WebService-FuncNet-Predictor-*' ],
);

$builder->create_build_script();
