use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(NAME => "WWW::NicoVideo",
	      VERSION_FROM => 'lib/WWW/NicoVideo.pm',
	      PREREQ_PM => {Web::Scraper => 0.2,
			    LWP => 5.8,
			    Class::Accessor => 0.2},
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => "lib/WWW/NicoVideo.pm",
		AUTHOR => 'HIRATA Yasuyuki <yasu@REMOVE-THIS-PART.asuka.net>'):
	       ()),
	     );
