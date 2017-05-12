use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Rakuten',
    VERSION_FROM      => 'lib/WebService/Rakuten.pm', # finds $VERSION
    PREREQ_PM         => {
        'Carp'              => 0,
        'JSON'              => 0,
        'LWP::UserAgent'    => 0,
        'Readonly'          => 0,
        'Test::More'        => 0,
        'Unicode::Japanese' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Rakuten.pod', # retrieve abstract from module
       AUTHOR         => 'Dylan Doxey <dylan.doxey@gmail.com>') : ()),
);
