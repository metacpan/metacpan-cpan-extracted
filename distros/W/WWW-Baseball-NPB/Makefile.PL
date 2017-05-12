use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WWW::Baseball::NPB',
    'VERSION_FROM' => 'lib/WWW/Baseball/NPB.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'LWP::Simple' => 0,
    },
);
