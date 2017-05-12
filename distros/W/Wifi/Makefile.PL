use ExtUtils::MakeMaker;

WriteMakefile(
		'NAME'	 => 'Wifi::Manage',
		'PM'	 => {
			'Manage.pm'	=> '$(INST_LIBDIR)/Manage.pm',
			'WFile.pm'	=> '$(INST_LIBDIR)/WFile.pm',
			'WDevIw.pm'	=> '$(INST_LIBDIR)/WDevIw.pm',
			'WDevIf.pm'	=> '$(INST_LIBDIR)/WDevIf.pm',
			'WRoute.pm'	=> '$(INST_LIBDIR)/WRoute.pm',
			'WMod.pm'	=> '$(INST_LIBDIR)/WMod.pm',
			},
		'VERSION_FROM'	=> 'Manage.pm',
);
					  
		 
