use 5.008;
use ExtUtils::MakeMaker;
#$Id: Makefile.PL,v 1.7 2005/08/15 15:53:59 kay Exp $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'warnings::DynamicScope',
    VERSION_FROM      => 'lib/warnings/DynamicScope.pm', # finds $VERSION
    PREREQ_PM         => {
						  Test::Exception	=> 0,
						  Test::Warn		=> 0,
						  Symbol::Values	=> 0,
						 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/warnings/DynamicScope.pm', # retrieve abstract from module
       AUTHOR         => 'Keitaro Miyazaki <kmiyazaki@cpan.org>') : ()),
);
