use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "Tk::FileDialog",
	      PM => { 'FileDialog.pm' => '$(INST_LIBDIR)/FileDialog.pm' },
              VERSION_FROM => 'FileDialog.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
             );
