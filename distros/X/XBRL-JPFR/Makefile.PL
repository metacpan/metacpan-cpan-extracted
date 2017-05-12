use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'XBRL::JPFR',
	VERSION_FROM    => 'lib/XBRL/JPFR.pm',
	PREREQ_PM		=> {
		'XBRL' => 0.03,
		'Hash::Merge' => 0.12,
		'Clone' => 0.31,
		'URI' => 1.64,
	},
);

