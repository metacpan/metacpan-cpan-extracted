use 5.007003; # the earlier perl doesn't have utf8 capabilities

use ExtUtils::MakeMaker;
BEGIN{ $ENV{AUTHOR} and require CPAN::Meta and CPAN::Meta->import();  };

WriteMakefile(
	NAME              => 'Test::More::UTF8',
	VERSION_FROM      => 'lib/Test/More/UTF8.pm',
	PREREQ_PM         => {
		'Test::More' => 0,
	},
	ABSTRACT_FROM     => 'lib/Test/More/UTF8.pm', # retrieve abstract from module
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LICENSE           => 'perl',
);
