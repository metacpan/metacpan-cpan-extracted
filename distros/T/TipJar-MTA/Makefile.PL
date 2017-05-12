use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'TipJar::MTA',
    'VERSION_FROM'	=> 'MTA.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		dateheader => 0,
		Net::DNS => 0.38
     }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MTA.pm', # retrieve abstract from module
       AUTHOR     => 'David Nicol <davidnico@cpan.org>') : ()),
);
