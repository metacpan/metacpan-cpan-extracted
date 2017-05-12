
use Config;

use ExtUtils::MakeMaker;

my $VERSION = '0.20';


WriteMakefile(
	NAME		=> 'LiveGeez',
	DISTNAME	=> 'Zobel',
	VERSION		=> $VERSION,
	PREREQ_PM	=> Convert::Ethiopic,
	dist		=> {
		COMPRESS => 'gzip -9f',
		SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
);

