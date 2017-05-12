use ExtUtils::MakeMaker;
use Getopt::Long;
# you must - repeat MUST have Perl 5.8 or greater !!!!
require 5.008;

use vars qw($opt_source $opt_addlibs $opt_embed_manifest $opt_help);

&GetOptions("source=s", \$opt_source, "addlibs=s", \$opt_addlibs, "embed-manifest", \$opt_embed_manifest, "help", \$opt_help);


# spew forth the help
if ($opt_help){
print <<HELP;

==================================================================
BUILDING HELP
==================================================================

Hello - you obviously need Help! :-)

The whole trouble with the build process is one 
of determining what your OS is, and which RFC
library needs to be linked in, and where that 
library lives.

To help with this there are two command line
options that you can use to point me in the 
right direction:

(1) --source /usr/sap/nwrfcsdk
  This tells me where to look for your installed
  RFCSDK.  This must be the directory that contains
  the ./lib and ./include directories of the RFCSDK
  In the include directory must be saprfc.h etc.
  By default, this looks in /usr/sap/nwrfcsdk.
  librfccm is taken in preference to librfc.

(2) --addlibs ' -lm -ldl -lpthread '
  This tells me what additional libraries need to
  be passed in at link time - this can be anything
  that you would put in LDFLAGS.
  By default this is ' -lm -ldl -lpthread '

(3) --embed-manifest 
  used for the win32 build to embed the manifest file.

Example:

perl Makefile.PL --source /opt/nwrfcsdk --addlibs '-lsomethingwacky'

==================================================================

HELP
;
  exit;
}


sub MY::subdirs {                                                                                       
  my $self = shift;
  my $section = $self->MM::subdirs;
  if ($^O =~ /MSWin32/i) {
    $section =~ s|(cd \.\.)(\s*$)|$1/..$2|m;
  }
  return $section;
}

sub MY::ppd {                                                                                       
  my $self = shift;
  my $section = $self->MM::ppd;
  if ($^O =~ /MSWin32/i) {
    $section =~ s|Test-More|Test::More|m;
  }
  return $section;
}


WriteMakefile(
    clean => { 'FILES'    => 'CPICTRC* ./examples/*.trc ./examples/CPICTRC* *.trc *~ core test*.txt *.tar.gz *.i *.ii' },
    dist => { 'TARFLAGS'    => 'cvf',
              'COMPRESS'        => 'gzip -9f',
            'SUFFIX'    => '.tgz'},
    'DIR' => [ 'lib/SAPNW' ],
    'PREREQ_PM' => { 'YAML' => 0, 'Test::More' => 0 },
    'AUTHOR' => 'Piers Harding <piers@cpan.org>',
    'ABSTRACT' => 'sapnwrfc - SAP Netweaver RFC support for Perl',
    'VERSION_FROM'    => 'sapnwrfc.pm',
    'NAME'    => 'sapnwrfc',
);

