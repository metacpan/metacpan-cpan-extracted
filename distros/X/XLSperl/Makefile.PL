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
		'NAME'         => 'XLSperl',
                'AUTHOR'       => 'Jon Allen <jj@jonallen.info>',
                'ABSTRACT'     => 'Use Perl "one-liners" with Microsoft Excel (.xls) files',
                'VERSION_FROM' => 'bin/XLSperl',
		'EXE_FILES'    => [ 'bin/XLSperl' ],            
		'PREREQ_PM'    => { 'Spreadsheet::ParseExcel'         => 0, 
                                    'Variable::Alias'                 => 0,
                                    'Spreadsheet::WriteExcel::Simple' => 0 },
		'MAN1PODS'     => {
			'bin/XLSperl' => "\$(INST_MAN1DIR)/XLSperl.1",
			},

		clean => { FILES => "*.bak XLSperl-*" },
		);
        
1;
