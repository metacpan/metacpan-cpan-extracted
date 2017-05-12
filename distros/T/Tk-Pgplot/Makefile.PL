#Override these values via comman-line arguments (IDIR=... LDIR=... XDIR=...) if need be

# IDIR = PGPLOT include file directory
# LDIR = PGPLOT library file directory
# XDIR = X11 library files directory

my %DefArg = (
                IDIR => $ENV{PGPLOT_DIR} || '/usr/include,/usr/local/pgplot',
	        LDIR => $ENV{PGPLOT_DIR} || '/usr/lib,/usr/local/pgplot',
	        XDIR => '/usr/openwin/lib,/usr/X11R6/lib'
             );


#######################################################
# There should be no need to edit the rest of this file
#######################################################

use Tk::MMutil;

use ExtUtils::F77;

while( $_ = shift @ARGV ) {
  if ( /^([\S]+)=(.+)/ && exists $DefArg{$1} ) {
    $DefArg{$1} = $2;
  }
}

my $LDIRS = join(' ', map {  "-L$_" }
		   map { split( ',', $_ ) }
		   @DefArg{qw/ XDIR LDIR /}
		  );

my $IDIRS = join( ' ', map { "-I$_" } split( ',', $DefArg{IDIR} ) );


Tk::MMutil::TkExtMakefile(
    NAME         => 'Tk::Pgplot',
    INC          => $IDIRS,
    LIBS         => ["$LDIRS ".
			  "-lptkpgplot -lcpgplot -lpgplot -lX11 ".
			  ExtUtils::F77->runtime],
    VERSION_FROM => 'Pgplot.pm',
    MYEXTLIB     => '',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);


