use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.1.1.1 2015/04/18 18:43:42 rkiesling Exp $
# Refer to lib/Extutils/MakeMaker.pm for details of 
# how to influence the contents of the Makefile that
# is written.

WriteMakefile( NAME => 'Browser::LibModule',
	       VERSION_FROM => 'LibModule.pm',
	       );

WriteMakefile( NAME => 'Browser::LibModuleSymbol',
	       VERSION_FROM => 'LibModuleSymbol.pm',
	       );

WriteMakefile( NAME => 'Browser::LibSymbolRef',
	       VERSION_FROM => 'LibSymbolRef.pm',
	       );
