use ExtUtils::MakeMaker;

# FIND POSSIBLE RFC INSTALLATIONS
my @POSSIBLE_RFC_DIRS = qw(/usr/sap/nwrfcsdk /usr/local /usr);
my $EMBED_MANIFEST= 0;

# the ADDITIONAL_LIBS needs to be modified for each OS flavour - the nwrfcsdk
# has the information regarding where libs and incs resides for each
# system type

# This SHOULD work for most cases (well at least Win32, and Linux)
my $ADDITIONAL_LIBS = '-lm -ldl -lrt -lpthread ';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#  inorder for the linktype dynamic to work, perl must be built with
#  threads, and the rfc library included - see running Configure for perl

use File::Basename qw(dirname basename);
use Getopt::Long;
use vars qw($opt_source $opt_addlibs $opt_embed_manifest $opt_help);

&GetOptions("source=s", \$opt_source, "addlibs=s", \$opt_addlibs, "embed-manifest", \$opt_embed_manifest, "help", \$opt_help);

$EMBED_MANIFEST = 1 if $opt_embed_manifest;

if($^O eq 'MSWin32') {
  $ADD_FLAGS = " -DWIN32";
#  $ADD_FLAGS .= " -D_DEBUG";
  $ADD_FLAGS .= " -D_CONSOLE";
  $ADD_FLAGS .= " -DUNICODE";
  $ADD_FLAGS .= " -D_UNICODE";
  $ADD_FLAGS .= " -DSAPwithUNICODE ";
  $ADD_FLAGS .= " -DSAPonNT ";
  $ADD_FLAGS .= " -DSAP_PLATFORM_MAKENAME=ntintel ";
} elsif($^O eq 'aix') {
  $ADD_FLAGS  = $Config{ccflags} . ' ' . $Config{ccflags_uselargefiles};
  $ADD_FLAGS .= " -DSAPwithUNICODE ";
  $ADD_FLAGS .= " -DSAPonUNIX ";
  $ADD_FLAGS .= " -D_AIX51 -D_LARGE_FILES -U__unix -q64 -qtbtable=full -qhalt=e -qalias=noansi -qfdpr -O -qstrict -qlibansi -qinlglue -qmaxmem=8192 -qarch=ppc -qtune=pwr5 -qspill=2560 -DSAPonRS6000 -D__NO_XLC_BUILTIN_VA ";
  $ADD_FLAGS .= " -DSAPwithTHREADS ";
  $ADD_FLAGS .= " -DNDEBUG ";
  $ADDITIONAL_LIBS = '-lm -ldl -lrt -lnsl -lpthread -licudecnumber ';
} elsif($^O eq 'solaris') {
  $ADD_FLAGS  = $Config{ccflags} . ' ' . $Config{ccflags_uselargefiles};
  $ADD_FLAGS .= " -DSAPwithUNICODE ";
  $ADD_FLAGS .= " -DSAPonUNIX ";
  $ADD_FLAGS .= " -DSAPonSUN -D__EXTENSIONS__ -D__XPG4_CHAR_CLASS__ -D_POSIX_PTHREAD_SEMANTICS -xchar=unsigned -xustr=ascii_utf16_ushort -w -xO3 -xcode=pic32 -mt -norunpath -R -z rescan ";
  $ADD_FLAGS .= " -DSAPwithTHREADS ";
  $ADD_FLAGS .= " -DNDEBUG ";
  $ADDITIONAL_LIBS = '-lm -ldl -lrt -lnsl -lpthread -licudecnumber ';
} elsif($^O eq 'hpux') {
  $ADD_FLAGS  = $Config{ccflags} . ' ' . $Config{ccflags_uselargefiles};
  $ADD_FLAGS .= " -DSAPwithUNICODE ";
  $ADD_FLAGS .= " -DSAPonUNIX ";
  $ADD_FLAGS .= " -D__NO_MATH_INLINES ";
  $ADD_FLAGS .= " -DSAPwithTHREADS ";
  $ADD_FLAGS .= " -DSAPonHPIA64 +DD64 +DSitanium2 -Aa +Olibmerrno +Oinitcheck +We281 +W392,829,818,887 -mt -w +O2 +Onolimit +Oprocelim -DNDEBUG ";
  $ADDITIONAL_LIBS = '-lm -ldl -lrt -lnsl -lpthread -licudecnumber -lCsup -lunwind ';
} else {
  $ADD_FLAGS  = $Config{ccflags} . ' ' . $Config{ccflags_uselargefiles};
  $ADD_FLAGS .= " -DSAPwithUNICODE ";
  $ADD_FLAGS .= " -DSAPonUNIX ";
  $ADD_FLAGS .= " -D__NO_MATH_INLINES -fPIC ";
  $ADD_FLAGS .= " -DSAPwithTHREADS ";
}

my ($iconv_inc, $iconv_lib);
if ($opt_iconv){
	$iconv_inc = $opt_iconv."/include";
	$iconv_lib = $opt_iconv."/lib";
	die "iconv include dir does not exist ($iconv_inc)\n" unless -d $iconv_inc;
	die "iconv lib dir does not exist ($iconv_lib)\n" unless -d $iconv_lib;
	$iconv_inc = "-I".$iconv_inc;
	$iconv_lib = "-L".$iconv_lib." -liconv";
  print "Iconv directory specified: adding $iconv_inc and $iconv_lib\n";
}


$ADDITIONAL_LIBS = $opt_addlibs if $opt_addlibs;
unshift(@POSSIBLE_RFC_DIRS, $opt_source) if $opt_source;

my $currdir = dirname($0) || '.';
chdir($currdir) || die("can't change to $currdir: $!");
if($^O eq 'MSWin32') {
    unshift(@POSSIBLE_RFC_DIRS, 'C:/Program Files/SAP/FrontEnd/SAPgui/nwrfcsdk', 'c:/nwrfcsdk');
}

my @CANDIDATE;
my $dir;
for $dir (@POSSIBLE_RFC_DIRS) {
    next unless -d $dir;
    my $candidate = Candidate($dir);
    next unless $candidate && $candidate->[2];
    push(@CANDIDATE, $candidate);
}

if (@CANDIDATE == 1) {
    my($dir, $inc_dir, $lib) = @{$CANDIDATE[0]};
    print "Found $lib installed in $dir\n";
} elsif (@CANDIDATE > 1) {
    print "Found the following libsapnwrfc installations:\n";
    for (@CANDIDATE) {
    my($dir, $inc_dir, $lib) = @$_;
      print "\t$lib\t$dir\n";
    }
}

my $RFC_DIR;
if($opt_source && (@CANDIDATE == 1) && $CANDIDATE[0][0]) {
    $RFC_DIR = $CANDIDATE[0][0];
    print "Using --source libsapnwrfc candidate found at $RFC_DIR\n";
} else {
    if($ARGV[0] =~ /^[a-z]\:|^\//i) {
    $RFC_DIR = shift;
    } else {
    unless($CANDIDATE[0][0]) {
          print "No libsapnwrfc installation found, usually in $POSSIBLE_RFC_DIRS[0]\n";
    }
    $RFC_DIR = prompt "Which libsapnwrfc build path do you want to link against?", $CANDIDATE[0][0];
    }
  }

my $candidate = &Candidate($RFC_DIR);
unless($candidate) {
    warn "Apparently no libsapnwrfc installation at '$RFC_DIR'\nAre you sure you got it correct????\n"
      unless -f "$RFC_DIR/include/sapnwrfc.h";
}
$candidate ||= ["$RFC_DIR", "$RFC_DIR/include", 'sapnwrfc'];
  
$RFC_INC = "$RFC_DIR/include";
  
if($^O =~ /Win32/) {
    unless($RFC_DIR =~ /^[a-zA-Z]\:/) {
    # default drive c
    $RFC_DIR = "c:".$RFC_DIR;
    }
    unless($RFC_INC =~ /^[a-zA-Z]\:/) {
      # default drive c
      $RFC_INC = "c:".$RFC_INC;
    }
    $RFC_INC = "\"$RFC_INC\"";
    $RFC_DIR =~ s|/|\\|g;
    $RFC_INC =~ s|/|\\|g;

    # patch from Ben Laurie
    if(-d "$RFC_DIR/lib") {
      $RFC_LIB = "-L\"$RFC_DIR/lib\"";
    } elsif(-d "$RFC_DIR/out32dll") {
      $RFC_LIB = "-L\"$RFC_DIR\\out32dll\"";
    }else {
    # Allow developers to point at libsapnwrfc source...
      $RFC_LIB = "-L\"$RFC_DIR\"";
    }

    $SEP = "\\";
    $LIBS = ' -l'.$candidate->[2].' -llibsapucum';
} else {
    $RFC_LIB = "-L".$RFC_DIR."/lib";
    $SEP = "/";
    $LIBS = ' -l'.$candidate->[2].' -lsapucum';
}

my $candidate_info = join('; ', @$candidate);
  
print <<INFO;

================================================
BUILD INFORMATION
================================================

source opt:          $opt_source
addlibs opt:         $opt_addlibs
embed_manifest opt:  $opt_embed_manifest
ADD_CFLAGS:          $ADD_FLAGS
sapnwrfc dir:        $RFC_DIR
libraries:      		 $ADDITIONAL_LIBS $RFC_LIB $LIBS
include dir:    		 $RFC_INC
sapnwrfc header:     $RFC_INC/sapnwrfc.h
sapnwrfc candidate:  $candidate_info

================================================

INFO
;


WriteMakefile(
    clean => { 'FILES'    => 'CPICTRC* ./.rfc_cache/* ./examples/.rfc_cache/* ./examples/*.trc ./examples/CPICTRC* *.inl *.trc testconn ./examples/testconn *~ core test*.txt *.tar.gz *.i *.ii' },
    dist => { 'TARFLAGS'    => 'cvf',
              'COMPRESS'        => 'gzip -9f',
            'SUFFIX'    => '.tgz'},
    'AUTHOR' => 'Piers Harding <piers@cpan.org>',
    'ABSTRACT' => 'Perl extension for performing RFC Function calls against an SAP NetWeaver System',
    'LINKTYPE'    => 'dynamic',
    'VERSION_FROM'    => 'Connection.pm',
    'NAME'    => 'SAPNW::Connection',
     DEFINE => " $ADD_FLAGS ",

    'LIBS'      => ["$ADDITIONAL_LIBS $RFC_LIB $LIBS $iconv_lib"],
    'INC'    => "-I".$RFC_INC ." ".$iconv_inc,

);

sub MY::makefile { '' }

sub MY::processPL { '' }


sub MY::constants {
    package MY;
    my $class = shift;
    my $inherited = $class->SUPER::constants(@_);
#    warn "CONSTANTS: $inherited\n";
	  if ($^O =~ /MSWin32/i){
      $inherited =~ s|\s\Q..\blib\E| ..\\..\\blib|g;
	  } else {
      $inherited =~ s|\s\Q../blib\E| ../../blib|g;
		}
    return $inherited;
}


sub MY::c_o {
  my $self = shift; 
  my $section = $self->MM::c_o;
  if ($^O !~ /(MSWin32|hpux|solaris)/i){
    $section =~ s/(\$\*\.i)/$1i\n\t\$\(FULLPERL\) ..\/..\/tools\/u16lit\.pl \-le \$\(BASEEXT\)\.ii/s;
		#.c$(OBJ_EXT):
		#        $(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c
		#
    $section =~ s/(\.c\$\(OBJ_EXT\)\:.*? \$\*\.)c/$1i/s;
    #print STDERR "c_o: $section\n";
	}
  return $section;
}


# add the manifest for win32
sub MY::dynamic_lib { 
  my $self = shift; 
  my $section = $self->MM::dynamic_lib;
	if ($^O =~ /MSWin32/i && $EMBED_MANIFEST){
	  $section .= "\tcd ..\\..\\blib\\arch\\auto\\SAPNW\\Connection\n";
	  $section .= "\tmt.exe -outputresource:Connection.dll;2 -manifest Connection.dll.manifest\n";
	  $section .= "\tcd ..\\..\\..\\..\\..\\lib\\SAPNW\n";
	}
  if ($^O !~ /(MSWin32|hpux|solaris)/i){
	  $section =~ s/(\$\(INST_DYNAMIC\)\: )/$1\$\(BASEEXT\)\.i /s;
	#  print STDERR "dynamic_lib: $section\n";
	}
	return $section;
}


sub Candidate {
    my $dir = shift;
    my $inc_dir;
    my @libs = ();

    for (
     "$dir/include/sapnwrfc.h"
    ) 
      {
      if(-e $_) {
          $version_file = $_;
      } 
      }
    return unless defined $version_file;

    my $dirname = $inc_dir = dirname($version_file);
    return unless (-e "$dirname/sapnwrfc.h");

    # Silly test to look for the library files
    my $libd = (-d "$dir/out32dll") ? 'out32dll' : 'lib';
    if (opendir(LIBDIR, "$dir/$libd")) {
    while (defined($_ = readdir(LIBDIR))) {
      push(@libs, 'sapnwrfc') if /sapnwrfc/i;
    }
    closedir(LIBDIR);
    }
    warn "$dir/lib does not seem to contain the libsapnwrfc library files\n"
        unless scalar @libs;
    @libs = reverse sort @libs;

    [$dir, $inc_dir, shift @libs];
}

