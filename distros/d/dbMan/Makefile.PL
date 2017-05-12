# BEGIN { $^W = 1 }
BEGIN { require 5.003 }

use ExtUtils::MakeMaker;
use strict;

use FindBin;

# Some MakeMaker's forged some FileHandle methods
require FileHandle unless defined(&FileHandle::new);

eval 'use DBI';
if ($@) {
	print <<EOF;
You do not seem to have DBI installed, so you will not be able to use
retrieve and update database functions for dbMan.
EOF
} elsif (eval ' $DBI::VERSION < 1.20 ') {
	print <<EOF;
You have the DBI module, but it's the old version. Upgrade to at least 1.20
to use this with dbMan.
EOF
}

my %opts = (
	NAME => 'dbMan',
	DISTNAME => 'dbMan',
	VERSION_FROM => 'lib/DBIx/dbMan.pm',
	EXE_FILES => [ "bin/dbman" ],
	dist => { DIST_DEFAULT => 'tardist',
		  COMPRESS => 'gzip -9vf', SUFFIX => 'gz',
		  POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
		},
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
	$opts{AUTHOR} = 'Milan Sorm (sorm@is4u.cz)';
	$opts{ABSTRACT} = 'Database management tool/front-end (SQL console)';
	$opts{PREREQ_PM} = { DBI => '1.20', 'Locale::gettext' => '1.01',
			'Text::FormatTable' => 0, 'Term::Size' => 0,
			'Text::CSV_XS' => 0, 'Data::ShowTable' => 0,
			'Data::Dumper' => 0, 'Term::Screen' => 0,
			'Term::ReadLine' => 0, 'Term::ReadKey' => 0,
			'Cwd' => 0 };
	if (uc prompt("Do you want tab completation in command line version [Y/n]?",'Y') eq 'Y') {
		$opts{PREREQ_PM}->{'Term::ReadLine::Gnu'} = 0;
	}
	if (uc prompt("Do you want also curses version [Y/n]?",'Y') eq 'Y') {
		$opts{PREREQ_PM}->{Curses} = '1.08';
		$opts{PREREQ_PM}->{'Curses::UI'} = '0.95';
		push @{$opts{EXE_FILES}},'bin/cdbman';
	}
	if (uc prompt("Do you want also Tk version [y/N]?",'N') eq 'Y') {
		push @{$opts{EXE_FILES}},'bin/xdbman';
		$opts{PREREQ_PM}->{Tk} = 0;
	}
}

ExtUtils::MakeMaker::WriteMakefile(%opts);

exit 0;

package MY;

__END__

