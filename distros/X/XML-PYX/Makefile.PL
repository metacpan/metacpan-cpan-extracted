use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::PYX',
    'VERSION_FROM' => 'PYX.pm', # finds $VERSION
	'AUTHOR' => 'Matt Sergeant',
	'ABSTRACT_FROM' => 'PYX.pm',
	'PREREQ_PM' => {
				'XML::Parser' => '2.23',
				},
	'EXE_FILES' => [ 'pyx', 'pyxv', 'pyxw', 'pyxhtml' ],
	'dist' => {
					'PREOP' => 'perl -MPod::Text -e "pod2text(q(PYX.pm))" > README',
				},
	);
