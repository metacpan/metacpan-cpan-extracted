use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	      ABSTRACT_FROM => q[DTDReader.pm],
	      AUTHOR => q[Alex Vandiver <alexmv@perl.org>],
	      DISTNAME => q[XML-Simple-DTDReader],
	      NAME => q[XML::Simple::DTDReader],
	      PREREQ_PM => { XML::Parser=>q[2.28] },
	      VERSION_FROM => q[DTDReader.pm],
	     );
