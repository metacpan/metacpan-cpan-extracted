use ExtUtils::MakeMaker;
$mylib=`xml2-config --libs`;
$myinc=`xml2-config --cflags`;

$Verbose = 1;
WriteMakefile(
	NAME   => 'Mytest2::canon',
	LIBS   => [$mylib], # e.g., '-lm'
    	DEFINE => '', # e.g., '-DHAVE_SOMETHING'
    	INC    => '-I. ' . $myinc, # e.g., '-I. -I/usr/include/other'

	SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	clean  => {'FILES' => 'libcanon$(LIBEEXT)'},
);

sub MY::top_targets {
	'
all :: static

pure_all :: static

static ::       libcanon$(LIB_EXT)

libcanon$(LIB_EXT): $(O_FILES)
	$(AR) cr libcanon$(LIB_EXT) $(O_FILES)
	$(RANLIB) libcanon$(LIB_EXT)

';
}  
