use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Wiki::Toolkit::Plugin::Diff',
    'VERSION_FROM'	=> 'lib/Wiki/Toolkit/Plugin/Diff.pm', # finds $VERSION
    'PREREQ_PM'		=> {VCS::Lite => '0.05',
    			    Wiki::Toolkit => 0,
    			    Module::Optional => 0,
			    Params::Validate => 0,
    			    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Wiki/Toolkit/Plugin/Diff.pm', # retrieve abstract from module
       AUTHOR     => 'Ivor Williams (IVORW (at) cpan [dot] org)') : ()),
);
