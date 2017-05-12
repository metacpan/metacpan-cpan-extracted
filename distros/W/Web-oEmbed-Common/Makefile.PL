use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
    'NAME'			=> 'Web::oEmbed::Common',
	AUTHOR          => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
	# ABSTRACT_FROM => 'lib/Web/oEmbed/Common.pm', 
    'VERSION_FROM' 	=> 'lib/Web/oEmbed/Common.pm', 
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    	? ('LICENSE'=> 'perl')
    	: ()
	),
    'PREREQ_PM'		=> {
		'Web::oEmbed' => 0.01,
	}, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Web-oEmbed-Common-*' },
);

########################################################################

sub MY::postamble { <<'<<' }

again: realclean FORCE
	perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

%.t: pm_to_blib FORCE
	make; perl -Iblib/lib $@

cover: FORCE
	cover -delete; HARNESS_PERL_SWITCHES=-MDevel::Cover make test; cover

<<

1;