# -*-perl-*-
# Makefile.PL for w3mir.
# Note that the file 'MANIFEST' is quite significant in this context
#
# Notes:  Should unpack any tar.gz files in current directory and install
#   them with identical arguments to Makefile.PL to this invocation.
#   This is especially for making installation of w3mir easy 
#   by installing libwww-perl and mime-base64 for the user before
#   installing w3mir.  Cool eh?  That would require some changes.
#
# - janl 18/4/1997
#
# 19/04/99 janl: Added 'clean' target on tip from  Lupe Christoph
#	and LWP max-version check to the LWP detection.
# 

# First just write the Makefile
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> 'w3mir',
    VERSION_FROM => 'w3mir.PL', # finds $VERSION
    EXE_FILES => [ 'w3mir', 'w3mfix' ],
    clean => { FILES => 'w3mir w3mfix' },
    dist => { COMPRESS => 'gzip -f9', SUFFIX => 'gz' },
);

print "\n";

# Find value of INSTALLSITELIB

&read_makefile;
$islib = resolve_make_var('INSTALLSITELIB');

# Check for prerequisites

$| = 1;
my $missing_modules = 0;

# libwww-perl
print "Checking for libwww-perl:";

eval "use lib '$islib'; require LWP;";

if (!defined($LWP::VERSION)) {
  print ' failed

libwww seems to be missing.

';
  $missing_modules++;
  sleep(2);
} elsif ($LWP::VERSION<5.08) {
  print ' failed

libwww is version ',$LWP::VERSION,', I need version 5.08 or later
Please see the INSTALL file.

';
  $missing_modules++;
  sleep(2);
} else {  
  print " ok\n\n";
}

# MIME::Base64
print "Checking for MIME::Base64:";

eval "use lib '$islib'; require MIME::Base64;";

if (!defined(&MIME::Base64::encode)) {
  print ' failed

MIME::Base64 seems to be missing.

';
  $missing_modules++;
  sleep(2);
} else {
  print " ok\n\n";
}


print 'Please see the INSTALL file for instructions on how to get the
missing/too old modules.

' if $missing_modules;


sub resolve_make_var ($) {

  my($var) = shift @_;
  my($val) = $make{$var};

#  print "Resolving: ",$var,"=",$val,"\n";
  
  while ($val =~ s~\$\((\S+)\)~$make{$1}~g) {}
#  print "Resolved: $var: $make{$var} -> $val\n";
  $val;
}


sub read_makefile {

  open(MAKEFILE, 'Makefile') || 
    die "Could not open Makefile for reading: $!\n";

  while (<MAKEFILE>) {
    chomp;
    next unless m/^([A-Z]+)\s*=\s*(\S+)$/;
    $make{$1}=$2;
#    print "Makevar: $1 = $2\n";
  }

  close(MAKEFILE)
}
