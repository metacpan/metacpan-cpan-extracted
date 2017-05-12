# $Source: /home/keck2/xwin/taskbar/makemaker/RCS/Makefile.PL,v $
# $Revision: 1.8 $$Date: 2007/07/06 16:45:16 $

@exe = qw(
  bin/mk.xchar
  bin/mk.xscreens
  bin/mk.xtb
  bin/xscreens
  bin/xdeco
  bin/xmv
  bin/xtb
  bin/xtc
  bin/xterms
  bin/xup
);

for (@exe) {
  ($base) = m-.*/(.*)-;
  $man1pods{$_} = "\$(INST_MAN1DIR)/$base.1p";
}

@mod = qw(
  lib/X11/Screens.pm
  lib/X11/Tops.pm
  lib/X11/XTerms.pm
);

for (@mod) {
  ($base) = m-.*/(.*)-;
  $man3pods{$_} = "\$(INST_MAN3DIR)/X11::$base.3p";
}

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'xchar',
  VERSION_FROM => 'version',
  EXE_FILES => [ @exe ],
  MAN1PODS => {
    'xchar.pod' => "\$(INST_MAN1DIR)/xchar.1p",
    %man1pods
  },
  MAN3PODS => { %man3pods },
  PREREQ_PM => {
    Tk => 8.0, # dunno really
    'X11::Protocol' => 0.55, # dunno really
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

