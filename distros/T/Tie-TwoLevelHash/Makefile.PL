# Makefile.PL for Tie::TwoLevelHash

use ExtUtils::MakeMaker;

WriteMakefile(	NAME	 => 'Tie::TwoLevelHash',
		VERSION_FROM => 'TwoLevelHash.pm',
		'clean'	 => {FILES => q[*% *.bak *.old *.tlh]},
		'dist'   => {COMPRESS => 'gzip -9f',
			     SUFFIX   => 'gz', 
			     POSTOP   => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
			     DIST_DEFAULT => 'all tardist',
			    },
	     );
