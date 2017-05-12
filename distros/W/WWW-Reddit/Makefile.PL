use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Reddit',
    VERSION_FROM      => 'lib/WWW/Reddit.pm', # finds $VERSION
    PREREQ_PM         => {
        'LWP::Simple'     => 0,
        'LWP::UserAgent'  => 0,
        'JSON'            => 0,
        'HTTP::Cookies'   => 0,
        'Data::Dumper'    => 0,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Reddit.pm', # retrieve abstract from module
       AUTHOR         => 'jon <jon@>') : ()),
);
