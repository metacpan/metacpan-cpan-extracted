use strict;
use warnings;
use inc::Module::Install;
use 5.008;

name 'WebService-FuncNet-Predictor';
perl_version '5.008';
all_from 'lib/WebService/FuncNet/Predictor.pm';
license 'perl';

# prereqs

requires "File::Temp"                        => '0.21';
requires "LWP::UserAgent"                    => '5.822';
requires "Log::Log4perl"                     => '1.20';
requires "Moose"                             => '0.64';
requires "MooseX::Types"                     => '0.08';
requires "Readonly"                          => '1.03';
requires "URI"                               => '1.37';
requires "URI::Heuristic"                    => '4.18';
requires "URI::file"                         => '4.20';
requires "XML::Compile::Schema"              => '1.05';
requires "XML::Compile::Transport::SOAPHTTP" => '2.04';
requires "XML::Compile::WSDL11"              => '2.04';

# things the tests need
build_requires 'Test::More'      => '0.77';

tests_recursive();

auto_install;

WriteAll();
