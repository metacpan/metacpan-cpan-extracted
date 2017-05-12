use Test::Most;

use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );
	require Test::Pcuke::Tests::Mockery; Test::Pcuke::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Report');
}

done_testing();
__END__
{
	skip 'need less integrated tests!';
	my $mocks = get_mocks();
	
	my $reporter = Test::Pcuke::Report->new(
		features	=> [ $mocks->{feature} ],
		printer		=> $mocks->{printer},
		#debug		=> 'context',
	);
	
	$reporter->build();
	
	my $feature = $mocks->{feature};
	is(metrics($feature, 'title'),		1, "reporter asks for feature title");
	is(metrics($feature, 'narrative'),	1, "reporter asks for narrative");
	is(metrics($feature, 'background'),	1, "report asks for background");
	is(metrics($feature, 'scenarios'),1, "reporter asks for scenarios");
	
	my $background = $mocks->{feature}->background;
	is(metrics($background, 'title'),	1, "title of the background were requested");
	is(metrics($background, 'steps'),	1, "steps of the background were requested");
	for my $step ( @{ $background->steps } ) {
		is(metrics($step, 'type'),		1, "each background step is asked for type");
		is(metrics($step, 'title'),		1, "each background step is asked for title");
		is(metrics($step, 'text'),		1, "each background step is asked for text");
	}
	
	for my $scenario ( @{ $mocks->{feature}->scenarios } ) {
		is(metrics($scenario,'title'),	1, "each scenario is queried for a title");
		is(metrics($scenario, 'steps'),1, "each scenario is queried for steps");
		is(metrics($scenario, 'scenarios'),1, "each scenario is queried for scenarios");
		for my $step ( @{ $scenario->steps } ) {
			is(metrics($step, 'text'),	1, "each step is queried for text");
			is(metrics($step, 'table'),	1, "each step is queried for table");
		}
		for my $example ( @{ $scenario->scenarios } ) {
			is(metrics($example, 'title'),	1, "each examples queried for a title");
			is(metrics($example, 'table'),	1, "each examples queried for table");
			
			my $table = $example->table;
			is(metrics($table, 'headings'),	1, "table is asked for headings");
			is(metrics($table, 'rows'),		1, "table is queried for rows");
			
			foreach my $row ( @{ $table->rows } ) {
				is(metrics($row, 'data'),	1, "each row is queried for data");
			}
		}
	}
	
	
	
	is(metrics($mocks->{printer},'print'),				1, "report was printed out");
}

done_testing();
### helpers
sub get_mocks {
	my $mocks;
	
	$mocks->{printer} = omock('printer');
	
	$mocks->{feature} = omock('feature', {
		background	=> get_mocks_background(),
		scenarios	=> get_mocks_scenarios(),
	});
	
	return $mocks;
}

sub get_mocks_background {
	return omock('background', {
		steps	=> [ omock('step'), omock('step') ]
	});
}

sub get_mocks_scenarios {
	return [
		omock('scenario', {
			steps		=> [
				omock('step', {
					table	=>  omock('table', {
					headings	=> ['a', 'b', 'c'],
					rows => [
						omock('trow', {
							data	=> { a=>'aaa', b=>'bbb', c=>'ccc'},
						}),
						omock('trow', {
							data	=> { a=>'ddd', b=>'eee', c=>'fff'},
						})
					],
				}), 
				} )
			],
			examples	=> [],
		} ),
		omock('outline', {
			steps		=> [ omock('step') ],
			examples	=> get_examples(),
		} ),
	];
}

sub get_examples {
	return [
		omock('scenarios', {
			table => omock('table', {
				headings	=> ['a', 'b', 'c'],
				rows => [
					omock('trow', {
						data	=> { a=>'aaa', b=>'bbb', c=>'ccc'},
					}),
					omock('trow', {
						data	=> { a=>'ddd', b=>'eee', c=>'fff'},
					})
				],
			}),
		}),
		omock('scenarios', {
			table => omock('table', {
				headings	=> ['a', 'b', 'c'],
				rows => [
					omock('trow', {
						data	=> { a=>'aaa', b=>'bbb', c=>'ccc'},
					}),
					omock('trow', {
						data	=> { a=>'ddd', b=>'eee', c=>'fff'},
					})
				],
			}),
		})
	];
}