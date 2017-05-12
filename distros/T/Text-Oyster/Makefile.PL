use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Text::Oyster',
    'VERSION_FROM' => 'Oyster.pm', # finds $VERSION
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	PREREQ_PM => {
		Parse::Tokens => 0.17,
    }
);
