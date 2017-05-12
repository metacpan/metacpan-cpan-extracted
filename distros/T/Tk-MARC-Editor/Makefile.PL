use 5.6.0;
use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Find;

find( \&filecheck, "." );

sub filecheck {
    unlink if /~$/;  # Remove any emacs backup files
    die "Aborting: Swapfile $_ found" if /\.swp$/;
}

&WriteMakefile(
	'NAME'		=> 'Tk::MARC::Editor',
	'DISTNAME'	=> 'Tk-MARC-Editor',
	'VERSION_FROM'	=> 'lib/Tk/MARC/Editor.pm', # finds $VERSION
	'PMLIBDIRS'	=> [ qw( lib/ ) ],
	'AUTHOR'	=> 'David Christensen <David-A-Christensen@gmail.com> (replace dash with period)',
	'PREREQ_PM'	=> {
			   'Test::More' => 0,
			   'Tk' => 0,
			   'MARC::Record' => 1.34,
			   'MARC::Lint' => 0,
			   'MARC::Errorchecks' => 0,
			   'MARC::Descriptions' => 0,
			   },
	'ABSTRACT_FROM' => 'lib/Tk/MARC/Editor.pm',
	'EXE_FILES'	=> [ qw( ) 
			     ],
	'dist'		=> {
			   COMPRESS => 'gzip -9f',
			   SUFFIX => 'gz',
			   },
	'depend'	=> {
			   Makefile => '$(VERSION_FROM)'
			   },
);
