#!/usr/bin/env perl
use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long qw(GetOptions);
use File::Copy;

GetOptions(\my %opt,
   'no-programs|n'
) or do {
    die "Usage: $0 [--no-programs|-n] \n";
};

my @prog;
push(@prog, qw(xml_repo.pl))
    unless $opt{'no-programs'} || grep /^LIB=/, @ARGV;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME              => 'blx::xsdsql'
	,VERSION_FROM      => 'lib/blx/xsdsql/version.pm'
	,PREREQ_PM         => { 
						  'XML::Parser' 	=> '1.21' 
						, 'XML::Writer' 	=> '0.600'
						, 'DBI'			=> '1.616'
						, 'Carp::Assert'	=> '0.20'
						, 'DBD::DBM'		=> '0.06'
						, 'MLDBM'		=> '2.05'
						, 'SQL::Statement'	=> '1.33'
						, 'Attribute::Constant'	=> '0.06'
						, 'Modern::Perl'	=> '1.20121103'
						, 'Filter::Include'	=> '1.6'
	}
	,LICENSE 	=> "perl"
	,EXE_FILES 	=> [ map "bin/$_", @prog ]
	,ABSTRACT 	=> 'stored xml into databases'
	,AUTHOR     	=> 'lorenzo bellotti <pauseblx@gmail.com>'
	,clean 		=> { FILES => "  *.old t/xml_*/*.sql   t/xml_*/*.diff t/xml_*/*.tmp  t/xml_*/.step* " }
);


exit 0;

