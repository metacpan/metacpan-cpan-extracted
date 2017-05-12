use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'Tk::JBrowseEntry',
	VERSION_FROM => 'lib/Tk/JBrowseEntry.pm',
	PM => { 
	  'lib/Tk/JBrowseEntry.pm' => '$(INST_LIBDIR)/JBrowseEntry.pm' 
	},
	EXE_FILES => ['JBrowseTest.pl'],
	'dist' => { COMPRESS=>'gzip -9f', SUFFIX => 'gz' },
	($ExtUtils::MakeMaker::VERSION gt '6.30'? 
	  ('LICENSE'		=> 'perl', ) : ()),
	PREREQ_PM    => {
#	  'Test::More'      => '0.47',
	  'Tk'      => '0',
	}
);
