use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Text::Annotated::Line',
    'VERSION_FROM' => 'lib/Text/Annotated/Line.pm', # finds $VERSION
    ($] > 5.004) ? (
       ABSTRACT => 'Annotates lines with their source file and line number',
       AUTHOR   => 'Wim Verhaegen <wimv@cpan.org>',
    ) : (),
    'PREREQ_PM' => { 'Text::Filter' => 1.7 },
    'clean'        => {
        FILES => '*/*/*/*~ */*/*/*/*~ */*/*/*/*/*~ */*/*/*/*/*/*~'
    }, # for those deep dirs
    'dist'         => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Text-Annotated-Line-$(VERSION_SYM)' 
    }, # support Concurrent source Versioning System
);
