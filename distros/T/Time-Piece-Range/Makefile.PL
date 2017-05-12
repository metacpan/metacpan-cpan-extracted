use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'          => 'Time::Piece::Range',
	'ABSTRACT_FROM' => 'lib/Time/Piece/Range.pm',
	'AUTHOR'        => 'Tony Bowden <TMTM@cpan.org>',
	'VERSION_FROM'  => 'lib/Time/Piece/Range.pm',
	'PREREQ_PM'     => {
		'Time::Piece' => '1.08',
		'Date::Range' => '1.2',

	},
);
