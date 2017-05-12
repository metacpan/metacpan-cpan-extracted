

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Ubic::Watchdog::Notice',
	VERSION_FROM => 'lib/Ubic/Watchdog/Notice.pm', # finds \$VERSION
	AUTHOR       => 'Alexey Likhatskiy <likhatskiy\@gmail.com>',
	ABSTRACT     => 'Notice service for ubic',
	EXE_FILES    => [
		"bin/ubic-notice"
	],
	PREREQ_PM    => {
		'Test::Simple'   => 0.44,
		'Getopt::Long'   => 0,
		'File::Tail'     => 0,
		'MIME::Lite'     => 0,
		'URI'            => 0,
		'LWP::UserAgent' => 0,
	},
);
