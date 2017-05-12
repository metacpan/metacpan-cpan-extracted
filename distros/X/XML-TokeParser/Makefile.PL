use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $file = 'TokeParser.pm';
WriteMakefile(
    'NAME'	=> 'XML::TokeParser',
    'VERSION_FROM'	=> $file,
    'PREREQ_PM'		=> {
        'XML::Parser' => 2,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => $file, # retrieve abstract from module
       AUTHOR     => 'D.H. aka PodMaster'
       ) : ()),
);
