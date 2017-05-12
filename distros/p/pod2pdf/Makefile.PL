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
		'NAME'         => 'pod2pdf',
                'AUTHOR'       => 'Jon Allen <jj@jonallen.info>',
                'ABSTRACT'     => 'Converts Pod to PDF format',
                'VERSION_FROM' => 'lib/App/pod2pdf.pm',
		'EXE_FILES'    => [ 'bin/pod2pdf' ],            
		'PREREQ_PM'    => { 'PDF::API2'        => 0.60,
                                    'Pod::Parser'      => 0,
                                    'Pod::ParseLink'   => 0,
                                    'Pod::Escapes'     => 0,
                                    'Getopt::ArgvFile' => 0 },
		'MAN1PODS'     => {
			'bin/pod2pdf' => "\$(INST_MAN1DIR)/pod2pdf.1",
			},

		clean => { FILES => "*.bak pod2pdf-*" },
		);
        
1;
