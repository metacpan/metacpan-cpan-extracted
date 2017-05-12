use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Facebook::FQL',
    VERSION_FROM      => 'FQL.pm', # finds $VERSION
    PREREQ_PM         => {
        WWW::Mechanize => 0,
        Digest::MD5 => 0,
        URI::Escape => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'FQL.pm', # retrieve abstract from module
       AUTHOR         => 'Sean O\'Rourke <seano@cpan.org>') : ()),
);
