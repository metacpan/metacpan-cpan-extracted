use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Bizowie::API',
    VERSION_FROM      => 'lib/WWW/Bizowie/API.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::UserAgent' => 0, 'HTTP::Request::Common' => 0, 'Try::Tiny' => 0, 'JSON' => 0, 'Mo' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Bizowie/API.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Aquilina <aquilina@cpan.org>') : ()),
);

