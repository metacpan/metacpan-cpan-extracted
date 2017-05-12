use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => "WWW::Yahoo::InboundLinks",
	VERSION_FROM => "lib/WWW/Yahoo/InboundLinks.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	PREREQ_PM => {
		'LWP::UserAgent' => 0,
		'JSON' => 2.10,
	}
);
