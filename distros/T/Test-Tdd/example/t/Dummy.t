use strict;
use warnings;
use Test::Spec;

describe 'Math test' => sub {
	it 'works' => sub {
		is(1 + 1, 2);
	};
};

runtests;