# $Id: Makefile.PL,v 1.4 2001/12/14 03:24:06 sps Exp $
use ExtUtils::MakeMaker;
use strict;

my ($vhome, $version, $prefive, $INC, $LIBS, $DEF);

print "**\nI will try to configure myself\n";
print "If this fails try editing and running Makefile.attic\n**\n\n";

$vhome = (getpwnam(q(vpopmail)))[7];

print "vpopmail lives in: $vhome\n";

open(FH, sprintf("%s/etc/inc_deps", $vhome)) || $prefive++;

if (! $prefive ) {

  chomp($INC = <FH>);

  close(FH);

}


open(FH, sprintf("%s/etc/lib_deps", $vhome)) || $prefive++;

if (! $prefive ) {

  chomp($LIBS = <FH>);

  close(FH);

}

open(FH, sprintf("%s/include/vpopmail_config.h", $vhome)) || die $!;

while (my $line = <FH>) {

  chomp($line);

  if ($line =~ m!#define VERSION "([^\.]+)! ) {

      $version = $1;

  }

}

if (! $version || $version < 5 ) {

  print "vpopmail version: $version\n";

  $DEF = '-DPREFIVE';

} else {

  $DEF = '';

}

print "includes: $INC\nlibs: $LIBS\ndefs: $DEF\n\n";

##############################
WriteMakefile(
	      'NAME'	=> 'vpopmail',
	      'VERSION_FROM' => 'vpopmail.pm', # finds $VERSION
	      'LIBS'	=> [$LIBS],   # e.g., '-lm'
	      'DEFINE'	=> $DEF,     # e.g., '-DHAVE_SOMETHING' 
	      'INC'	=> $INC
);
