use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'Video::RTjpeg',
    VERSION_FROM => 'RTjpeg.pm',
    OBJECT       => '$(BASEEXT)$(OBJ_EXT) codec/RTjpeg.o',
);

sub MY::postamble { <<EOF
codec/RTjpeg.c: codec/compose.sh
	cd codec && . compose.sh

codec/RTjpeg.o: codec/RTjpeg.c codec/RTjpeg.h
	\$(CCCMD) \$(CCCDLFLAGS) -o \$@ \$<
EOF
}
