use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Time::Normalize',
    'VERSION_FROM'	=> 'lib/Time/Normalize.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::Simple' => '0.40'},
    'PL_FILES'          => {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Time/Normalize.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Roode <roode@cpan.org>') : ()),
);
