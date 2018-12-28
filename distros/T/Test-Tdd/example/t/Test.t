use strict;
use warnings;
use Test::Spec;

require_ok('Module::Code');
require_ok('Module::ImmutableMooseClass');

describe 'My test' => sub {
	it 'returns correctly' => sub {
		is(Module::Code::foo(), 'bar');
	};
};

runtests;