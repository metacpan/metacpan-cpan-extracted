use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Printf',
    VERSION_FROM      => 'lib/Text/Printf.pm', # finds $VERSION
    PREREQ_PM         =>
    {
     'Test::More'         => '0.40',
     'Readonly'           => '1.00',
     'Exception::Class'   => '1.21',
    },
    PL_FILES          => {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Text/Printf.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Roode <roode@cpan.org>') : ()),
);
