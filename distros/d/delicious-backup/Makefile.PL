use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'delicious-backup',
  ABSTRACT      => 'simple del.icio.us backup tool',
	AUTHOR        => 'Ricardo SIGNES <rjbs@cpan.org>',
	VERSION_FROM  => 'bin/delbackup',
	EXE_FILES     => [ 'bin/delbackup' ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
	PREREQ_PM => {
		'Config::Auto'        => 0.11,
		'Net::Delicious'      => 1.11, # 1.10 has a bug in using "updates"
		'YAML'                => 0,
		'Netscape::Bookmarks' => 0,
	},
);

