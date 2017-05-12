use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Time::Object',
    'VERSION_FROM' => 'Object.pm', # finds $VERSION
	'dist'	=> {
			'PREOP' => 'perl -MPod::Text -e "pod2text(q(Object.pm))" > README',
		},
);
