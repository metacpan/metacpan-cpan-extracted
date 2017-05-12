use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::JavE',
    'VERSION_FROM'	=> 'lib/Text/JavE.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::More' => 1.001003,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Text/JavE.pm', # retrieve abstract from module
       AUTHOR     => 'osfameron - osfameron@cpan.org') : ()),
);
