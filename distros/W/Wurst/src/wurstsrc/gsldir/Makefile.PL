#Builds an archive (static library) containing miniGSL symbols
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
    'NAME'	=> 'LibMiniGSL',
    'LINKTYPE'	=> 'static',
    'CCFLAGS'	=> "$ccflags",
    'OBJECT'	=> 'blas$(OBJ_EXT) error$(OBJ_EXT) permutation_init$(OBJ_EXT) lu$(OBJ_EXT) init$(OBJ_EXT) view$(OBJ_EXT) strerror$(OBJ_EXT) block_init$(OBJ_EXT) matrix$(OBJ_EXT) matrix_view$(OBJ_EXT) matrix_init$(OBJ_EXT) matrix_rowcol$(OBJ_EXT) matrix_swap$(OBJ_EXT) erfc$(OBJ_EXT) stream$(OBJ_EXT)',
    'INC'	=> '-I..',
    'clean'	=> {'FILES' => 'libminigsl$(LIB_EXT) *~'},
    macro	=> {
		    ADD_AR_OPT	  => ($add_ar_flags || ''),
		    MY_CC_PRE_TARGET => ($Using_ms_vc
					 ? '-Fo'
					 : ($Using_Borland
					    ? '-o': '-o $(MY_EMPTY_STR)')),
		    MY_AR_PRE_TARGET => ($Using_ms_vc
					 ? '-out:'
					 : ($Using_Borland
					    ? '' : 'cr $(MY_EMPTY_STR)')),
		    MY_AR_OBJECT => ($Using_Borland
				     ? '$(OBJECT:^"+")'
				      : '$(OBJECT)'),
		    MY_EMPTY_STR  => '',
		   },
);

sub MY::top_targets {
  '
all :: libminigsl$(LIB_EXT)

static ::       libminigsl$(LIB_EXT)

libminigsl$(LIB_EXT): $(OBJECT)
	-$(RM_F) libminigsl$(LIB_EXT)
	$(AR) $(ADD_AR_OPT) $(MY_AR_PRE_TARGET)libminigsl$(LIB_EXT) $(MY_AR_OBJECT)
	$(RANLIB) libminigsl$(LIB_EXT)
';
}
