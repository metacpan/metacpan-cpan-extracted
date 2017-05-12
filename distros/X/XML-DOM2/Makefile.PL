use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'XML::DOM2',
	AUTHOR              => 'Martin Owens <doctormo@cpan.org>',
	VERSION_FROM        => 'lib/XML/DOM2.pm',
	PL_FILES            => {},
	PREREQ_PM => {
		'Test::More' => 0,
		'XML::SAX'   => 0.14,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'XML-DOM2-*' },
);
