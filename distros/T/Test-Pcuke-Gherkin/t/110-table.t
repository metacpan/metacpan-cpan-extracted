use Test::Most;
use FindBin qw{$Bin};

BEGIN {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
	else { die "wrong Bin path!" }	
	require lib; lib->import( "$Bin/lib" );
	
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Table');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Table';
my $CLASS_Row = 'Test::Pcuke::Gherkin::Node::Table::Row';

my $zerostats = { pass=>0, fail=>0, undef=>0};

new_ok($CLASS => [], 'table instance');
can_ok($CLASS, qw{set_headings headings add_row add_rows rows hashes});

{
	my $table = $CLASS->new();
	cmock('trow', { data => { h1=>11, h2=>12, h3=>13}, nsteps => $zerostats, nscenarios => $zerostats });
	$table->set_headings( [qw{h1 h2 h3}] );

	is_deeply($table->headings, [qw{h1 h2 h3}], 'headings are set');

	throws_ok {
		$table->add_row();
	} qr{either arrayref or Table::Row}, 'add_row() dies if the number of columns does not correspond the number of headings';
	
	$table->add_row( [ qw{11 12 13} ] );
	$table->add_row( [ qw{21 22 23} ] );
	
	is_deeply( $table->rows, [instance('trow',0), instance('trow', 1)], "Table::Row's are added to the Table");
	is_deeply( $table->hashes, [
		{ h1=>11, h2=>12, h3=>13},
		{ h1=>11, h2=>12, h3=>13}
	 ], "rows data can be accessed through hashes()");
}

{
	my $hash1 = { a=>'aaa', b=>'bbb', c=>'ccc'};
	my $hash2 = { a=>'111', b=>'222', c=>'333'};
	
	my $r1 = omock('trow', {
		nsteps => $zerostats,
		nscenarios => $zerostats,
		data	=> $hash1,
	});
	
	my $table = $CLASS->new;
	
	lives_ok {
		$table->add_row( $r1 );
	} 'can add T::C::Table::Row when headings are empty';
	
	is_deeply($table->hashes, [$hash1], "a row is stored in the table");
	is_deeply($table->headings, [keys %$hash1], "correct headings are set");
	
	my $rx = omock('trow', {
		data	=> { d=>'ddd', e=>'eee', f=>'fff'},
		nsteps => $zerostats, nscenarios => $zerostats
	});
	
	throws_ok {
		$table->add_row($rx);
	} qr{different}, "dies when a row with incorrect headings is added";
	
	my $r2 = omock('trow', {
		data	=> $hash2,
		nsteps => $zerostats, nscenarios => $zerostats
	});
	
	lives_ok {
		$table->add_row($r2);
	} 'can add a row with the identical headings'
}

{
	my $bgr = omock('background');
	
	my $s1 = omock('step' );
	my $s2 = omock('step' );

	my $r1 = omock('trow', {
		data		=> { a => 'aaa', b=>'bbb', c=>'ccc'},
		nsteps		=> { pass=>5, fail=>6, undef=>7 },
		nscenarios	=> { pass=>0, fail=>1, undef=>0 },
		execute		=> sub {
			is_deeply($_[1], [$s1, $s2], "row->execute: 1st arg is a ref to array of steps");
			is($_[2], $bgr, "row->execute: 2nd arg is a background");
		} 
	});
	
	my $r2 = omock('trow', {
		data		=> { a => 'ddd', b=>'eee', c=>'fff'},
		nsteps		=> { pass=>5, fail=>0, undef=>3 },
		nscenarios	=> { pass=>0, fail=>0, undef=>1 }, 
		execute		=> sub {
			is_deeply($_[1], [$s1, $s2], "row->execute: 1st arg is a ref to array of steps");
			is($_[2], $bgr, "row->execute: 2nd arg is a background");
		} 
	});
	
	my $r3 = omock('trow', {
		data		=> { a => 'ggg', b=>'hhh', c=>'iii'},
		nsteps		=> { pass=>4, fail=>0, undef=>0 },
		nscenarios	=> { pass=>1, fail=>0, undef=>0 }, 
		execute		=> sub {
			is_deeply($_[1], [$s1, $s2], "row->execute: 1st arg is a ref to array of steps");
			is($_[2], $bgr, "row->execute: 2nd arg is a background");
		} 
	});
	
	my $table = $CLASS->new;
	$table->add_rows([ $r1, $r2, $r3 ]);
	$table->execute([$s1, $s2], $bgr);
	
	is_deeply($table->nsteps,		{pass=>14, fail=>6, undef=>10}, "correct numbers of steps");
	is_deeply($table->nscenarios,	{pass=>1, fail=>1, undef=>1}, "correct numbers of scenarios");
}
done_testing();