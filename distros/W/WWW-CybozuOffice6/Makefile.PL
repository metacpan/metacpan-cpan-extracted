use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'WWW::CybozuOffice6',
	      VERSION_FROM => 'lib/WWW/CybozuOffice6.pm',
	      PREREQ_PM => { Carp => 0,
			     Jcode => 0,
			     LWP => 0,
			     Text::CSV_XS => 0,
			     URI::Escape => 0,
			 },
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => 'lib/WWW/CybozuOffice6.pm',
		AUTHOR => 'Kazuho Oku <kazuho ___at___ labs.cybozu.co.jp>') :
	       ()),
	      );
