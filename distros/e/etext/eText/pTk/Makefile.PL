use Config;
use ExtUtils::MakeMaker;
use Cwd;

my $dirTk;

if (defined $common::dirTk) {
  $dirTk = $common::dirTk;
} else {
  die "Expecting \$common::dirTk to be defined";
}

eval 'use Tk::Config';		# Get the constants

local $inc = $inc || $::inc || "";
$inc .= " -I. -I$dirTk/pTk -I$dirTk/pTk/mTk/xlib" ; 
local $gccopt = $::gccopt || $gccopt || "";

Tk::MMutil::TkExtMakefile(
    'NAME'      => 'Tk::eText::lib',
    'INC'	=> "$inc $gccopt",
    'clean' 	=> {'FILES' => 'libpTkeText$(LIB_EXT) *%'},
    SKIP      => [qw(all static static_lib dynamic dynamic_lib)],
);


sub MY::constants {
  my $self = shift;
  my $c = $self->MM::constants;
  if ($c =~ m,^INC\b.*/xlib($|\s),m) {
    $c =~ s,^INC\b.*,$& -I$dirTk/pTk/mTk/xlib,m ;
  }
  $c . "

TOP_TK = $dirTk

";
}

sub MY::post_constants {
  
  my $objects = "LIBOBJS =";
  my $len     = length($objects);
  my %seen;
  foreach (<tkT*.c mTk/tkText*.c pperlGlue.c>)
    {
      s/\.c/\$(OBJ_EXT)/;
      s,^mTk/,, ;
      next if $seen{$_}++;
      if (($len+length($_)+1) > 72)
	{
	  $objects .= "\\\n\t";
	  $len = 8;
	}
      $objects .= " $_";
      $len     += 1+length($_);
    } 
  $objects .= "\n";
  
  return "\n" . $objects;	# . &upgrade_pic();
};

sub MY::install {
'
install :: all
';
}

sub MY::top_targets {
  '
libpTkeText$(LIB_EXT): $(LIBOBJS)
	$(AR) cr $@ $(LIBOBJS)
	$(RANLIB) $@

$(LIBOBJS): $(HDRS)

config ::

' .
	shift->MM::top_targets
}

sub MY::postamble {
my $dep = join('',`cat $dirTk/pTk/tkText*.d`);
$dep =~ s:[ \t]\b: $dirTk/pTk/:g ;
$dep =~ s:\Q$dirTk\E/pTk/tkText:tkText:g ;
$dep =~ s:(.)(\s+\\)$:$1 pperl.h $2:gm ;
$dep . "
all :: static

static ::       libpTkeText\$(LIB_EXT)

Makefile : $dirTk/myConfig

Tcl-pTk: $dirTk/pTk/Tcl-pTk
	\$(CP) \$< \$@
";
}


