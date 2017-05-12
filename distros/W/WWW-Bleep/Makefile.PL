use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WWW::Bleep',
    VERSION_FROM      => 'lib/WWW/Bleep.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::UserAgent' => 0,
                           'HTML::TokeParser' => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Bleep.pm', # retrieve abstract from module
       AUTHOR         => 'Clif Bratcher <snevine@cpan.org>') : ()),
);
