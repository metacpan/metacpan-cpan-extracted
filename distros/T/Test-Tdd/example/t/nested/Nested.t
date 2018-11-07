use strict;
use warnings;
use Test::Spec;

describe 'Math test 2' => sub {
	it 'works' => sub {
		is(2 + 2, 4);
	};
};

runtests;