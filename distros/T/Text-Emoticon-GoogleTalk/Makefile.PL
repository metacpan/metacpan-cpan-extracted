use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Text::Emoticon::GoogleTalk',
    'VERSION_FROM' => 'lib/Text/Emoticon/GoogleTalk.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
