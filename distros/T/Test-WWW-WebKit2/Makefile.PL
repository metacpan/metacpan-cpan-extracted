use 5.010000;
use ExtUtils::MakeMaker;

my @authors = ( 'Jason  Shaun Carty <jc@atikon.com>',  'Philipp Voglhofer <pv@atikon.com>', 'Philipp A. Lehner <pl@atikon.com>');
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'Test::WWW::WebKit2',
    VERSION_FROM       => 'lib/Test/WWW/WebKit2.pm', # finds $VERSION
    LICENSE            => 'perl',
    PREREQ_PM          => {
        'WWW::WebKit2' => 0.126,
        'Test::More'   => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM   => 'lib/Test/WWW/WebKit2.pm', # retrieve abstract from module
       AUTHOR          => \@authors) : ()),
);
