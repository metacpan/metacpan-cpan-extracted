use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "Tk::WaitBox",
	      PM => { 'WaitBox.pm' => '$(INST_LIBDIR)/WaitBox.pm' },
              VERSION_FROM => 'WaitBox.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
             );
