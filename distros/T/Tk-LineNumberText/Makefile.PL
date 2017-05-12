use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Tk::LineNumberText',
	'AUTHOR'	=> 'Jack Dunnigan (goodcall1[at]hotmail.com)',
	'ABSTRACT'	=> 'Line numbers for your favorite Text-derived widget',
	'VERSION_FROM'	=> 'LineNumberText.pm',
	'dist'		=> {'COMPRESS'=>'gzip',
	'SUFFIX'	=> '.gz',
	'POSTOP'	=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
	'PREREQ_PM'	=> {
		'Tk'	=> 800.015,
			},

	'MAN3PODS'	=> {
		'LineNumberText.pm'   => '$(INST_MAN3DIR)/Tk::LineNumberText.$(MAN3EXT)',
		},
);
