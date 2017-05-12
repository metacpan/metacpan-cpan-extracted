use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Time::Duration::pt',
    'VERSION_FROM' => 'lib/Time/Duration/pt.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Time::Duration => 1.02,
    },
);
