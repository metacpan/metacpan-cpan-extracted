use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'Text::ChaSen',
	      'VERSION_FROM' => 'ChaSen.pm',
	      'LIBS' => ['-lchasen']
);
