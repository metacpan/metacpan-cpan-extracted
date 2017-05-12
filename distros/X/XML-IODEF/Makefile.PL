use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::IODEF',
    VERSION_FROM      => 'lib/XML/IODEF.pm', # finds $VERSION
    PREREQ_PM         => {
        XML::DOM            => '1.44', 
        XML::Parser         => '2.36', 
        XML::Parser::Expat  => '2.36',
        DateTime            => '0.47',
        XML::Simple         => '2.18',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/IODEF.pm', # retrieve abstract from module
       AUTHOR         => 'John Green johng@cpan.org, Wes Young <wes@barely3am.com>') : ()),
);
