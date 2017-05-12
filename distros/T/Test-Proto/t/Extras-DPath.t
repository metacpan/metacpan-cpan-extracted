#!perl 
use strict;
use warnings;
use Test::Proto::Base;
use Test::Proto qw(p pArray pHash);
use Test::More;

eval {
	require Data::DPath;
	Data::DPath->import();
};


plan skip_all => "Data::DPath required for testing integration with Data::DPath" if $@;

#subtest 'Test Data::DPath integration' => sub {

	my $data  = {
		AAA  => { BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
			RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
			DDD => { EEE  => [ qw/ uuu vvv www / ] },
		},
	};
#	use Data::Dumper;
	ok p->dpath_true('/AAA')->validate($data), 'dpath_true passes';
	ok (! (p->dpath_true('/BBB')->validate($data)), 'dpath_true fails correctly');
	ok p->dpath_false('/BBB')->validate($data), 'dpath_false passes';
	ok (! (p->dpath_false('/AAA')->validate($data)), 'dpath_false fails correctly');
	ok p->dpath_results('/AAA/*', pArray->count_items(3) )->validate($data), 'dpath_results must return an array with the relevant items';

#};


done_testing();
