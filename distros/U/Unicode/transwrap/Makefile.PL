use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
    NAME   => 'Unicode::Transliterate::transwrap',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'libtranswrap$(LIBEEXT)'},
);


sub MY::top_targets {
'
all :: static

pure_all :: static

static ::       libtranswrap$(LIB_EXT)

libtranswrap$(LIB_EXT): $(O_FILES)
	$(AR) cr libtranswrap$(LIB_EXT) $(O_FILES)
	$(RANLIB) libtranswrap$(LIB_EXT) ';
} 
