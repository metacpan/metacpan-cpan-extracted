use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    'NAME'		=> 'Wiki::Toolkit::Plugin::Ping',
    'VERSION_FROM'	=> 'lib/Wiki/Toolkit/Plugin/Ping.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP => 0,
    			    Wiki::Toolkit => 0,
    			    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Wiki/Toolkit/Plugin/Ping.pm', # retrieve abstract from module
       AUTHOR     => 'Nick Burch (openguides (at) gagravarr [dot] org)') : ()),
    clean          => { FILES => 't/sqlite-test.db' },
);
