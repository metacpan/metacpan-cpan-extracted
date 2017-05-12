use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Text::Filter::Chain',
    'VERSION_FROM' => 'lib/Text/Filter/Chain.pm', # finds $VERSION
    ($] > 5.004) ? (
      'ABSTRACT'  => 'Chains multiple filters and runs them sequentially',
      'AUTHOR'    => 'Wim Verhaegen <wim.verhaegen@ieee.org>',
    ) : (),
    'PREREQ_PM' => {'Text::Filter' => '1.7'},
    'EXE_FILES' => [],
    'clean'     => {FILES => '*/*/*/*~ */*/*/*/*~ */*/*/*/*/*~ */*/*/*/*/*/*~'}, # for those deep dirs
    'dist'      => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Text-Filter-Chain-$(VERSION_SYM)' 
     }, # support Concurrent source Versioning System
);
