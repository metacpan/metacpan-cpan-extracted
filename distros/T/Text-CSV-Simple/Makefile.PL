use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Text::CSV::Simple',
    'VERSION_FROM'	=> 'lib/Text/CSV/Simple.pm', 
    'PREREQ_PM'		=> { 
			'Text::CSV_XS' => 0,
			'File::Slurp' => 0,
			'Class::Trigger' => 0,
		},
);
