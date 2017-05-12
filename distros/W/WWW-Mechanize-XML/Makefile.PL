use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Mechanize::XML',
    VERSION_FROM      => 'lib/WWW/Mechanize/XML.pm', # finds $VERSION
    PREREQ_PM         => {
        Test::More => 0.47,
        Test::Exception => 0.20,
        WWW::Mechanize => 1.18,
        XML::LibXML => 1.58,
        File::Temp => 0.13
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Mechanize/XML.pm', # retrieve abstract from module
       AUTHOR         => 'Barry White <bwhite@fotango.com>') : ()),
);
