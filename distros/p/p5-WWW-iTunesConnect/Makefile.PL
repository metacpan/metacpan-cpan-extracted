use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::iTunesConnect',
    DISTNAME          => 'p5-WWW-iTunesConnect',
    VERSION_FROM      => 'lib/WWW/iTunesConnect.pm', # finds $VERSION
    PREREQ_PM         => { 'HTML::Form'             => 0,
                           'HTML::Tree'             => 0,
                           'IO::Uncompress::Gunzip' => 0,
                           'Net::SSLeay'            => 0,
                           'LWP'                    => 5.829,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/iTunesConnect.pm', # retrieve abstract from module
       AUTHOR         => 'Brandon Fosdick <bfoz@bfoz.net>') : ()),
);
