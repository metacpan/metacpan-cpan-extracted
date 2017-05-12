use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'		=> 'Tk::MiniScale',
	'AUTHOR'	=> 'Jack Dunnigan (dunniganj@cpan.org)',
	'ABSTRACT'	=> 'A miniature version of Tk::Scale',
	'VERSION_FROM'	=> 'MiniScale.pm',
	'dist'		=> {'COMPRESS'=>'gzip',
	'SUFFIX'	=> '.gz',
	'POSTOP'	=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
	'PM'		=> {
		'MiniScale.pm'	=> '$(INST_LIB)/Tk/MiniScale.pm',
			},
	
	'PREREQ_PM'	=> {
		'Tk'	=> 800.022,
		'Tk::Trace'	=> 1.0,
			},

	'MAN3PODS'	=> {
		'MiniScale.pm'   => '$(INST_MAN3DIR)/Tk::MiniScale.$(MAN3EXT)',
		},
);

