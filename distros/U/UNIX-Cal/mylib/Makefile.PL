use ExtUtils::MakeMaker;
#$Verbose = 1;
WriteMakefile(
     NAME   => 'libcal',
     SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
     clean  => {'FILES' => 'libcal$(LIBEEXT)'},
             );

sub MY::top_targets {
       '
all :: static

pure_all :: static

static ::       libcal$(LIB_EXT)

libcal$(LIB_EXT): $(O_FILES)
	$(AR) cr libcal$(LIB_EXT) $(O_FILES)
	$(RANLIB) libcal$(LIB_EXT)

          ';
}
