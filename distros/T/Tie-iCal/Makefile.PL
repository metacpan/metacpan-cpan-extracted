use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'         => 'Tie::iCal',
	'VERSION_FROM' => 'lib/Tie/iCal.pm',
	'PM' => {
		'lib/Tie/iCal.pm' => '$(INST_LIBDIR)/iCal.pm',
	},
	'PL_FILES' => {},
	'PREREQ_PM'   => {
		'Tie::File'	=> '0.97',
	},
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Blair Sutton (bsdz@cpan.org)',
		'ABSTRACT' => 'Tie iCal files to Perl hashes',
	)
	: (),
);


