#!perl -w

use strict;
use Test::More tests => 5;

use warnings::method;

ok !eval q{
	use warnings FATAL => 'syntax';

	UNIVERSAL::isa('UNIVERSAL', 'UNIVERSAL');
}, 'FATAL';
like $@, qr/^Method/, 'die with message';

{
	local $SIG{__WARN__} = sub{};

	ok eval q{
		use warnings;
		UNIVERSAL::isa('UNIVERSAL', 'UNIVERSAL');
	}, 'NONFATAL';
	if($@){
		diag $@;
	}
}
ok !eval q{
	use warnings::method 'foo';

	UNIVERSAL::isa('UNIVERSAL', 'UNIVERSAL');
}, 'Unknown subdirective';
like $@, qr/^Unknown mode foo/, 'die with usage';

