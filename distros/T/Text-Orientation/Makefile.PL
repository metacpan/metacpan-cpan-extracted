use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Orientation',
    'VERSION_FROM'	=> 'Orientation.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'String::Multibyte'  => '1',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Orientation.pm', # retrieve abstract from module
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
