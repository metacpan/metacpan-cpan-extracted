use Test::Most;
use FindBin qw{$Bin};

BEGIN: {
	if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin 
	else { die "wrong Bin path!" }
	
	require lib; lib->import( "$Bin/lib" );
	require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	
	use_ok('Test::Pcuke::Gherkin::Node::Background');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node::Background';

new_ok( $CLASS => [], 'background instance');
can_ok($CLASS, qw{title set_title steps add_step execute nsteps});


{	# set_title is immutable
	my $bgr = $CLASS->new();
	my $title = 'title';
	
	is($bgr->title, q{}, "undefined title is empty");
	
	$bgr->set_title($title);
	is($bgr->title, $title, "set_title() sets title");
	
	throws_ok {
		$bgr->set_title("$title$title");
	} qr{immutable}, "title is immutable";
	
}

{
	my $bgr = $CLASS->new();
	my $s1 = omock('step', {status => 'undef'} );
	my $s2 = omock('step', {status => 'pass' } );
	
	$bgr->add_step( $_ ) for ($s1, $s2);
	
	$bgr->execute();
	
	is( metrics($s1, 'execute'), 1, "step 1 was executed");
	is( metrics($s2, 'execute'), 1, "step 2 was executed");
	
	is_deeply($bgr->steps, [ $s1, $s2 ], "steps() returns arrayref of steps");
	is_deeply($bgr->nsteps, {fail=>0, pass=>1, undef=>1}, "number of steps is calculated correctly");
	
	$bgr->execute();
	is_deeply($bgr->nsteps, {fail=>0, pass=>1, undef=>1}, "number of steps depends only on the steps execution results");
}

{
	my $title = "background";
	my $s1 = omock('step', {status => 'undef'} );
	my $s2 = omock('step', {status => 'pass' } );
	
	my $bgr = $CLASS->new({
		title => $title,
		steps => [$s1, $s2] 
	});
	
	is($bgr->title, $title, "title can be passed as constructor argument");
	is_deeply($bgr->steps, [$s1, $s2], "steps can be passed to constructor");
}


done_testing();
__END__
