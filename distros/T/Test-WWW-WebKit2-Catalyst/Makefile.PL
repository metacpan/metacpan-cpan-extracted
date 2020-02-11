use 5.010000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my @authors = ( 'Jason Shaun Carty <jc@atikon.com>',  'Philipp Voglhofer <pv@atikon.com>', 'Philipp A. Lehner <pl@atikon.com>');
WriteMakefile(
    NAME              => 'Test::WWW::WebKit2::Catalyst',
    VERSION_FROM      => 'lib/Test/WWW/WebKit2/Catalyst.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::WWW::WebKit2'     => 0.1,
        'Test::More'             => 0,
        'IO::Socket::INET'       => 0,
        'Catalyst::EngineLoader' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/WWW/WebKit2/Catalyst.pm', # retrieve abstract from module
       AUTHOR         => '\@authors') : ()),
);
