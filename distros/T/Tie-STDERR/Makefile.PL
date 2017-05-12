
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'Tie::STDERR',
	'VERSION_FROM'	=> 'STDERR.pm',
        'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	);

