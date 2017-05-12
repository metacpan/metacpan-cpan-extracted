use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Text::Emoticon::MSN',
    'VERSION_FROM' => 'lib/Text/Emoticon/MSN.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Text::Emoticon => 0.02,
    },
);
