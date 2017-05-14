use ExtUtils::MakeMaker qw(&WriteMakefile);
use Cwd;

$Version = '0.61';
# The following guy should be defined if we are build inside Tk directory
$Tk::MMutil::dir = cwd unless defined $Tk::MMutil::dir;

my $dirTk;

local $inc    = $::inc || "";
$xlib   = $::xlib || "" if not defined $xlib;

$dirTk = ".." if -r "../tkGlue.h";	# Check whether we are in the Tk tree.

#unless (defined $dirTk) {
#  # We are compiled standalone, try my machine locations:
#  #$dirTk = "H:/get/perl/Tk400.200" if -r "H:/get/perl/Tk400.200/tkGlue.h";
#  $dirTk = "H:/get/perl/Tk401.000.pm" if -r "H:/get/perl/Tk401.000.pm/tkGlue.h";
#}

## If $dirTk is not defined, try to find it

#unless (defined $dirTk) {
#  if (-r "../Tk/tkGlue.h") {$dirTk = "../Tk";}
#  elsif (-r "Tk/tkGlue.h") {$dirTk = "Tk" }
#  elsif (-r "../../tkGlue.h") {$dirTk = "../.." }
#  elsif (-r "../../Tk/tkGlue.h") {$dirTk = "../../Tk" }
#  # Try harder
#  elsif (@list = <../../Tk-*> and -d $list[-1]) {$dirTk = $list[-1] }
#  elsif (@list = <../Tk-*> and -d $list[-1]) {$dirTk = $list[-1] }
#  die "Please define \$dirTk in Makefile.PL, cannot find it automatically.\n"
#    unless defined $dirTk;
#}


#print "Tk found in $dirTk.\n";

#eval 'use lib $dirTk';

require Tk::MMutil;

require Tk::Config;		# Get the constants if standalone

if (!defined $dirTk) {		# Not in the build tree
  require Tk::Text;		# Find the location
  
  my $tktext = $INC{'Tk/Text.pm'};
  print "tktext: `$tktext'\n";
  $tktext =~ s|(blib/lib/)?Tk/Text\.pm||;
  
  die "Tk::Text not in Tk directory `$tktext'" unless -f "$ {tktext}tkGlue.h";
  $dirTk = $tktext; # Communicate to the child
}

{				# Make the path absolute (for pTk subdir)
  my $d = cwd;
  chdir $dirTk or die "cannot chdir `$dirTk': $!";
  $dirTk = cwd;
  chdir $d or die "cannot chdir `$d': $!";
}

$common::dirTk = $dirTk;	# Communicate to the child

local $Tk::MMutil::define = $Tk::MMutil::define;
$Tk::MMutil::define .= " -DLangIsPerl";

$newTk = $Tk::Config::VERSION !~ /400/;
$Tk::MMutil::define .= " -DNEW_TK" if $newTk;
$mylibs = $newTk ? "" : "$xlib -lX11" ;
$myinc = $::inc || $inc;

$direText = "pTk";
$gccopt = $::gccopt if $::gccopt;

Tk::MMutil::TkExtMakefile(
    NAME     => 'Tk::eText',
    VERSION  => $Version,
    MYEXTLIB => "$direText/libpTkeText\$(LIB_EXT)",
    LIBS    => [ $mylibs ],
    INC     => "-I$dirTk/pTk $myinc -I$dirTk/pTk/mTk/Xlib $gccopt",
    OBJECT      => 'eText$(OBJ_EXT)',
);


sub MY::constants {
  my $self = shift;
  my $c = $self->MM::constants;
  if ($c =~ m,^INC\b.*/xlib($|\s),m) {
    $c =~ s,^INC\b.*,$& -I$dirTk/pTk/mTk/xlib,m ;
  }
  $c;
}

sub MY::post_constants {

 return # &upgrade_pic() . 
"
TK_DIR = $dirTk
eText_DIR = $direText
";
}

sub MY::postamble {
    '
Makefile     : $(TK_DIR)/myConfig 
$(BASEEXT)$(OBJ_EXT) : $(MYEXTLIB)

# Hack to make eText.pm:
$(MYEXTLIB)  : FORCE $(INST_LIB)/eText.pm
	cd $(eText_DIR); $(MAKE) libpTkeText$(LIB_EXT) $(PASTHRU)

#$(eText_DIR)/Makefile : $(eText_DIR)/Makefile.PL
#	cd $(eText_DIR); $(PERL) Makefile.PL

eText.xs : $(TK_DIR)/Text/Text.xs
	$(CP) $(TK_DIR)/Text/Text.xs $@
	$(PERL) -pi~ -e "s/([^_])Text/\1eText/g;" -e "s/\"text/\"etext/g" $@

eText.pm : $(TK_DIR)/Text/Text.pm cnvrt eText.xs
	$(CP) $(TK_DIR)/Text/Text.pm $@
	$(PERL) -pi~ cnvrt $@

$(INST_LIB)/eText.pm: eText.pm
	$(CP) eText.pm $@
';
}

