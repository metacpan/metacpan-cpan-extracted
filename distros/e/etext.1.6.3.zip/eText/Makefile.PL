use strict;
use Tk::MMutil;
use Tk::Config;



local $Tk::MMutil::define = $Tk::MMutil::define;
$Tk::MMutil::define .= " -DLangIsPerl";

local $::inc    = $::inc || "";
local $::xlib   = $::xlib || "";

my $newTk = $Tk::Config::VERSION !~ /400/;
$Tk::MMutil::define .= " -DNEW_TK" if $newTk;
my $mylibs = $newTk ? "" : "$::xlib -lX11" ;

local $::gccopt = $::gccopt if $::gccopt;

Tk::MMutil::TkExtMakefile(
			  'dynamic_ptk' => 1,
			  MYEXTLIB => "$direText/libpTkeText\$(LIB_EXT)",
			  LIBS    => [ $mylibs ],
			  INC     => "-I$dirTk/pTk $::inc -I$dirTk/pTk/mTk/Xlib $::gccopt",
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

