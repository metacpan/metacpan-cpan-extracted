use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Text::Emoticon',
    'VERSION_FROM' => 'lib/Text/Emoticon.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        UNIVERSAL::require => 0,
    },
);
