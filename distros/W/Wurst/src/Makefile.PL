# src Makefile
use ExtUtils::MakeMaker;
use Config;

# Here you can add additional compiler flags
$additionalccflags="";
# additionalgccflags are only used if the cc is a gcc
$additionalgccflags="";

$ccflags="$Config{'ccflags'} $additionalccflags";
if ($Config{'ccname'} eq "gcc" ) {
 $ccflags="$ccflags $additionalgccflags";
}

WriteMakefile(
      'OPTIMIZE'      => $OPTIMIZE,
      'CCFLAGS'       => "$ccflags",
      'NAME'          => 'Wurst',
      'VERSION_FROM'  => '../lib/Wurst.pm',     # finds $VERSION
      'DEFINE'        => $cflags,
      'MYEXTLIB'      => 'wurstsrc/libwurst$(LIB_EXT) wurstsrc/gsldir/libminigsl$(LIB_EXT)',
      'INC'           => '-Iwurstsrc -Iwurstsrc/gsldir',
      'INSTALLMAN3DIR'=> $man_dest,
      'clean'         => { 'FILES' => '*~'},
);

sub MY::postamble {
'
wurstsrc/gsldir/libminigsl$(LIB_EXT): wurstsrc/gsldir/Makefile
	@echo
	@echo "Starting to make wurstsrc/gsldir/libminigsl$(LIB_EXT)"
	cd wurstsrc/gsldir && $(MAKE) $(PASSTHRU)
	@echo "Finished making wurstsrc/gsldir/libminigsl$(LIB_EXT)"
	@echo

wurstsrc/libwurst$(LIB_EXT): wurstsrc/Makefile
	@echo
	@echo "Starting to make wurstsrc/libwurst$(LIB_EXT)"
	cd wurstsrc && $(MAKE) $(PASSTHRU)
	@echo "Finished making wurstsrc/libwurst$(LIB_EXT)"
	@echo
';
}

sub MY::test {
'
test:
	$(NOECHO) $(NOOP)
';
}
