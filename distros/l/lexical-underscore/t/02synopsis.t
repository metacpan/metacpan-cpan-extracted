no if $] > 5.018000, warnings => qw(experimental);

use Test::More;
BEGIN {
	$] >= 5.010 or plan skip_all => "test requires Perl 5.010";
};

	use 5.010;
	use lexical::underscore;
	#use Test::More;
	
	sub is_uppercase {
		my $var = @_ ? shift : ${lexical::underscore()};
		return $var eq uc($var);
	}
	
	my $thing = 'FOO';
	my $works = 0;
	
	given ( $thing ) {
		when ( is_uppercase ) { $works++ }
	}
	
	ok($works);
	done_testing();
