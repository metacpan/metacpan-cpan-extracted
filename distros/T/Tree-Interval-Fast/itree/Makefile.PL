use ExtUtils::MakeMaker;

$Verbose = 1;
WriteMakefile(
	      NAME   => 'Tree::Interval::Fast::itree',
	      SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	      clean  => {'FILES' => 'libitree$(LIB_EXT)'},
	     );

sub MY::top_targets {
'
all :: static
pure_all :: static
static ::       libitree$(LIB_EXT)
libitree$(LIB_EXT): interval.o interval_list.o interval_tree.o
	$(AR) cr libitree$(LIB_EXT) interval.o interval_list.o interval_tree.o
	$(RANLIB) libitree$(LIB_EXT)
';
}
