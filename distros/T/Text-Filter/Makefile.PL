# Makefile.PL -- Makefile for Text::Filter
# Author          : Johan Vromans
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan 17 13:26:26 2013
# Update Count    : 22
# Status          : Stable

# Verify perl version.
require 5.8.8;

use ExtUtils::MakeMaker;

my @scripts = qw();

my $x = WriteMakefile
  (
   NAME         => 'Text::Filter',
   ($] >= 5.005)
    ? (AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
       ABSTRACT	=> 'Base class for line based text processing modules',
      ) : (),
   VERSION_FROM => "lib/Text/Filter.pm",
   PREREQ_PM	=> { 'IO::File' => 0,
		     'Test::More' => 0,
		   },
   # EXE_FILES    => [ map { "scripts/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );

my $name    = $x->{NAME};
my $version = $x->{VERSION};

my $fh;
(my $mname = "$name") =~ s'::'-'g;
my $fname = "perl-$mname.spec";
if ( open ($fh, "$fname.in") ) {
    print "Writing RPM spec file...\n";
    my $newfh;
    open ($newfh, ">$fname");
    while ( <$fh> ) {
	s/%define modname .+/%define modname $mname/;
	s/%define modversion \d+\.\d+/%define modversion $version/;
	print $newfh $_;
    }
    close($newfh);
}
