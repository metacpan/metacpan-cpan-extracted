use Kelp::Base -strict;
use Test::More;
use Test::Exception;
use Whelk::Schema;
use Whelk;

use lib 't/lib';

################################################################################
# This tests whether the base for some whelk packages is strict
################################################################################

subtest 'schemas are strict' => sub {
	throws_ok {
		Whelk::Schema->build(
			test_int => {
				type => 'integer',
				minimum => 5,    # not supported yet
			},
		);
	} qr{attribute minimum is not valid for class .+Integer[^.]};

	throws_ok {
		Whelk::Schema->build(
			test_int => {
				type => 'array',
				properties => {
					type => 'boolean',
				}
			},
		);
	} qr{attribute properties is not valid for class .+Array[^.]};

	throws_ok {
		Whelk::Schema->build(
			test_int => {
				type => 'array',
				itmes => {
					type => 'boolean',
				}
			},
		);
	} qr{attribute itmes is not valid for class .+Array\Q. Did you mean items?\E};

	throws_ok {
		Whelk::Schema->build(
			test_int => {
				type => 'string',
				descrption => 'test',
			},
		);
	} qr{attribute descrption is not valid for class .+String\Q. Did you mean description?\E};

	# extended attribute
	lives_ok {
		Whelk::Schema->build(
			test_int => {
				type => 'string',
				example => 'a string',
			},
		);
	};
};

subtest 'endpoints are strict' => sub {
	throws_ok {
		my $app = Whelk->new(mode => 'typo');
	} qr{attribute respnose is not valid.+ \QDid you mean response?\E};
};

done_testing;

