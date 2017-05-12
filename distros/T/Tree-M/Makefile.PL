use ExtUtils::MakeMaker;

WriteMakefile(
    dist	=> {
	            PREOP	=> '(cat INSTALL; pod2text M.pm) | tee README > $(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    CC		=> 'g++',
    LD		=> 'g++',
    OPTIMIZE	=> '-O6 -funroll-all-loops',
    INC		=> '-IGiST -IMT',
    MYEXTLIB	=> 'GiST/libGiST.a MT/libMT.a',
    OBJECT	=> 'M$(OBJ_EXT) PMT$(OBJ_EXT)',
    NAME	=> 'Tree::M',
    VERSION_FROM => 'M.pm',
);

print <<EOF;

***
*** This module is written in C++, which is nontrivial to integrate into
*** most pre-built perls. If problems occur during compiling then edit (hack)
***
*** Makefile.PL
*** GiST/Makefile MT/Makefile
***
*** in this order. Especially wautch out for compile and optimization flags.
*** Have fun ;->
***

EOF

sub MY::postamble { <<'EOF' }

force :

GiST/libGiST.a: force
	cd GiST && $(MAKE) OPTIMIZE="$(OPTIMIZE)" CXX="$(CC)" LD="$(LD)" libGiST.a

MT/libMT.a: GiST/libGiST.a force
	cd MT && $(MAKE) OPTIMIZE="$(OPTIMIZE)" CXX="$(CC)" LD="$(LD)" libMT.a

clean ::
	cd MT && $(MAKE) clean
	cd GiST && $(MAKE) clean

EOF

