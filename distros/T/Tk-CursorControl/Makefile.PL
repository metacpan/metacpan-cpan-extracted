use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'		=> 'Tk::CursorControl',
	'AUTHOR'	=> 'Jack Dunnigan (dunniganj@cpan.org)',
	'ABSTRACT'	=> 'Manipulate the mouse cursor programmatically',
	'VERSION_FROM'	=> 'CursorControl.pm',
	'dist'		=> {'COMPRESS'=>'gzip',
	'SUFFIX'	=> '.gz',
	'POSTOP'	=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
	'PM'		=> {
		'CursorControl.pm'	=> '$(INST_LIB)/Tk/CursorControl.pm',
		'trans_cur.xbm'	=> '$(INST_LIB)/Tk/trans_cur.xbm',
		'trans_cur.mask'	=> '$(INST_LIB)/Tk/trans_cur.mask',
		'demos/cursor.pl'	=> ($] >= 5.005
					? '$(INST_ARCHLIB)'
					: '$(INST_LIB)') . '/Tk/demos/widtrib/cursor.pl',
			},
	
	'PREREQ_PM'	=> {
		'Tk'	=> 800.015,
		($^O =~ /(MSWin32|cygwin)/ ? ('Win32::API' => 0.20) : ()),
			},

	'MAN3PODS'	=> {
		'CursorControl.pm'   => '$(INST_MAN3DIR)/Tk::CursorControl.$(MAN3EXT)',
		},
);

sub MY::postamble {
	'
demo :: pure_all
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -I$(SITEARCHEXP)/Tk/demos/widget_lib -Mblib demos/cursor.pl
';
}
