use strict;
use warnings;
use Test::Spec;

require_ok('Module::Code');

describe 'My test' => sub {
	it 'returns correctly' => sub {
		is(Module::Code::foo(), 'bar');
	};
};

runtests;