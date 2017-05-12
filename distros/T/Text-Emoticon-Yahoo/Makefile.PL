use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Text::Emoticon::Yahoo',
    'VERSION_FROM' => 'lib/Text/Emoticon/Yahoo.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Text::Emoticon => 0.02,
    },
);
