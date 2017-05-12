use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Text::MessageFormat',
    'VERSION_FROM' => 'lib/Text/MessageFormat.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Text::Balanced' => 1.89,
    },
);
