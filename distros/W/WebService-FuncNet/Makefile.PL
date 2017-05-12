use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::FuncNet',
    AUTHOR              => 'Spiros Denaxas <s.denaxas at gmail.com>',
    VERSION_FROM        => 'lib/WebService/FuncNet.pm',
    ABSTRACT_FROM       => 'lib/WebService/FuncNet.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                        => 0,
        'Test::Deep'                        => 0,
        'Text::CSV'                         => 0, # for parsing output
        'LWP::UserAgent'                    => 0, # for fetching the WSDL
        'Carp'                              => 0, 
        'XML::Compile::WSDL11'              => 0, # for SOAP
        'XML::Compile::SOAP11'              => 0, # for SOAP
        'XML::Compile::Transport::SOAPHTTP' => 0, # for SOAP
        'XML::Compile::Schema'              => 0, # for SOAP
        'XML::Simple'                       => 0, # for results output
        'Math::BigFloat'                    => 0, # for parsing output
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-FuncNet-*' },
);