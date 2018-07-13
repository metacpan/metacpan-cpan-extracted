use ExtUtils::MakeMaker;
WriteMakefile(
		NAME => 'Tk::JFileDialog',
		VERSION_FROM => 'lib/Tk/JFileDialog.pm',
		PM => { 
		  'lib/Tk/JFileDialog.pm' => '$(INST_LIBDIR)/JFileDialog.pm'
		},
		EXE_FILES => ['JFileDialogTest.pl'],
		'dist' => { COMPRESS=>'gzip -9f', SUFFIX => 'gz' },
	($ExtUtils::MakeMaker::VERSION gt '6.30'? 
	  ('LICENSE'		=> 'perl', ) : ()),
	PREREQ_PM    => {
#	  'Test::More'      => '0.47',
	  'Tk'      => '0',
	  'Tk::JBrowseEntry' => '4.63',
	},
);
