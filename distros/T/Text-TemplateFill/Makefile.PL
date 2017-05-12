use ExtUtils::MakeMaker;
# SCCS: @(#)Makefile.PL 1.1 03/27/03 09:08:46
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::TemplateFill',
    'VERSION_FROM'	=> 'TemplateFill.pm', # finds $VERSION
    'PREREQ_PM'		=> {'POSIX'		=>	0,
			    'Math::Expression'	=>	1,
			    'Time::Local'	=>	0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TemplateFill.pm', # retrieve abstract from module
       AUTHOR     => 'Alain D D Williams <addw@phcomp.co.uk>') : ()),
);
