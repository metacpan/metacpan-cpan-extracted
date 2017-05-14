# $Id$
use ExtUtils::MakeMaker;

eval "use Test::Manifest";

unless( $@ )
	{
	no warnings;
	
	*ExtUtils::MM_Any::test_via_harness = sub
		{
		my($self, $perl, $tests) = @_;
	
		return qq|	$perl "-MTest::Manifest" | .
			qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
			qq|'\$(INST_ARCHLIB)')"\n|;
		};
	}



WriteMakefile(
		'NAME'         => 'a2pdf',
                'AUTHOR'       => 'Jon Allen <jj@jonallen.info>',
                'ABSTRACT'     => 'Converts ASCII text to PDF format, with optional line/page numbering and Perl syntax highlighting',
                'VERSION_FROM' => 'bin/a2pdf',
		'EXE_FILES'    => [ 'bin/a2pdf' ],            
		'PREREQ_PM'    => { 'PDF::API2' => 0.60, },
		'MAN1PODS'     => {
			'bin/a2pdf' => "\$(INST_MAN1DIR)/a2pdf.1",
			},

		clean => { FILES => "*.bak a2pdf-*" },
		);
        
1;
