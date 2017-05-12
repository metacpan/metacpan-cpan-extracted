use 5.005;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Text::WikiText',
	DISTNAME => 'wikitext-perl',
	dist => {
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
		COMPRESS => 'gzip --best --force',
	},
	INSTALLDIRS => 'site',
	EXE_FILES => [ 'bin/wikitext-convert' ],
	VERSION_FROM => 'lib/Text/WikiText.pm',
	ABSTRACT => 'Converting WikiText markup to other formats',
	AUTHOR => 'Enno Cramer <uebergeek@web.de>, Mikhael Goikhman <migo@homemail.com>',
);

open MANIFEST, "<MANIFEST";
my @old_lines = grep !/^META.yml/, <MANIFEST>;
close MANIFEST;
my @new_lines = map { "$_\n" } (
	qw(
		AUTHORS
		COPYING
		Makefile.PL
		MANIFEST
		INSTALL
		NEWS
		README
	),
	glob("bin/*"),
	glob("doc/*"),
	glob("t/*"),
	"lib/Text/WikiText.pm",
	glob("lib/Text/WikiText/*.pm"),
	glob("lib/Text/WikiText/*/*.pm"),
);
if (join(',', @old_lines) ne join(',', @new_lines)) {
	print "Creating MANIFEST file\n";
	open MANIFEST, ">MANIFEST" or die "Can't write MANIFEST: $!\n";
	print MANIFEST @new_lines;
	close MANIFEST;
}

