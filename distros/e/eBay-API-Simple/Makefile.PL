use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'eBay::API::Simple',
    VERSION_FROM      => 'lib/eBay/API/Simple.pm',
    PREREQ_PM         => {
        'XML::LibXML'    => 0,
        'HTTP::Headers'  => 0,
        'HTTP::Request'  => 0,
        'LWP::UserAgent' => 0,
        'XML::Parser'    => 0,
        'XML::Simple'    => 0,
        'URI'            => 1.57,
        'URI::Escape'    => 0,
        'YAML'           => 0,
        'JSON'           => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/eBay/API/Simple.pm', #abstract from module
       AUTHOR         => 'Tim Keefer <tkeefer@gmail.com>') : ()),
);


