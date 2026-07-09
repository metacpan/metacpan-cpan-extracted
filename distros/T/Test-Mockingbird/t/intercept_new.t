use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

# -----------------------------------------------------------------
# Subject classes
# -----------------------------------------------------------------
{
	package My::Service;
	sub new  { bless { built => 1 }, $_[0] }
	sub type { 'real' }
}

{
	package My::Double;
	sub new  { bless { double => 1, @_[1..$#_] }, $_[0] }
	sub type { 'double' }
}

{
	package My::NoNew;
	# deliberately has no new() — relies on UNIVERSAL / inheritance
}

# =================================================================
# Plain-value form: same object returned on every call
# =================================================================

subtest 'intercept_new — plain object returned every call' => sub {
	my $stub = bless { id => 99 }, 'My::Service';

	intercept_new 'My::Service' => $stub;

	my $a = My::Service->new;
	my $b = My::Service->new(name => 'foo');

	is $a, $stub, 'first call returns stub';
	is $b, $stub, 'second call returns same stub';
	is ref($a), 'My::Service', 'blessed class preserved';

	restore_all();
	my $real = My::Service->new;
	isnt $real, $stub,       'original constructor restored';
	is $real->{built}, 1,    'real object has expected structure';
};

subtest 'intercept_new — plain scalar value' => sub {
	intercept_new 'My::Service' => 'sentinel';

	my $got = My::Service->new;
	is $got, 'sentinel', 'plain scalar returned';

	restore_all();
};

subtest 'intercept_new — plain undef value' => sub {
	intercept_new 'My::Service' => undef;

	my $got = My::Service->new;
	ok !defined $got, 'undef returned on every call';

	restore_all();
};

# =================================================================
# Coderef / factory form: original arguments forwarded
# =================================================================

subtest 'intercept_new — coderef receives class name and args' => sub {
	my @captured;

	intercept_new 'My::Service' => sub {
		push @captured, [@_];
		return bless { from_factory => 1 }, $_[0];
	};

	my $obj = My::Service->new(role => 'admin');

	is scalar @captured, 1, 'factory called once';
	is $captured[0][0], 'My::Service', 'class name forwarded as first arg';
	is $captured[0][1], 'role',        'named arg key forwarded';
	is $captured[0][2], 'admin',       'named arg value forwarded';
	ok $obj->{from_factory},           'factory return value is what caller receives';

	restore_all();
};

subtest 'intercept_new — coderef can return a different class' => sub {
	intercept_new 'My::Service' => sub {
		my ($class, %args) = @_;
		return My::Double->new(%args);
	};

	my $obj = My::Service->new(x => 7);

	isa_ok $obj, 'My::Double', 'factory can return a different class';
	is $obj->{x}, 7, 'args forwarded to factory object';

	restore_all();
};

# =================================================================
# restore_all / unmock
# =================================================================

subtest 'intercept_new — restore_all reinstates original' => sub {
	intercept_new 'My::Service' => bless {}, 'My::Double';

	is ref(My::Service->new()), 'My::Double', 'intercepted';

	restore_all();

	is ref(My::Service->new()), 'My::Service', 'original restored after restore_all';
};

subtest 'intercept_new — unmock by full name reinstates original' => sub {
	intercept_new 'My::Service' => bless {}, 'My::Double';

	is ref(My::Service->new()), 'My::Double', 'intercepted';

	unmock 'My::Service::new';

	is ref(My::Service->new()), 'My::Service', 'original restored after unmock';
};

# =================================================================
# Stacking
# =================================================================

subtest 'intercept_new — stacking two interceptors, LIFO restore' => sub {
	my $first  = bless { layer => 1 }, 'My::Service';
	my $second = bless { layer => 2 }, 'My::Service';

	intercept_new 'My::Service' => $first;
	intercept_new 'My::Service' => $second;

	my $got = My::Service->new();
	is $got, $second, 'top layer (second) is active';

	unmock 'My::Service::new';

	$got = My::Service->new();
	is $got, $first, 'after unmock, first layer is active';

	unmock 'My::Service::new';

	$got = My::Service->new();
	is ref($got), 'My::Service', 'after second unmock, original restored';
};

# =================================================================
# diagnose_mocks records the correct type
# =================================================================

subtest 'intercept_new — recorded as intercept_new in diagnose_mocks' => sub {
	intercept_new 'My::Service' => bless {}, 'My::Double';

	my $diag = diagnose_mocks();
	is $diag->{'My::Service::new'}{layers}[0]{type},
		'intercept_new', 'layer type is intercept_new';

	restore_all();
};

# =================================================================
# Class without its own new (inherited)
# =================================================================

subtest 'intercept_new — class with no own new, inherited constructor' => sub {
	# My::NoNew inherits new from UNIVERSAL.
	# Intercepting it should still work.
	my $stub = bless { stub => 1 }, 'My::NoNew';

	intercept_new 'My::NoNew' => $stub;

	my $obj = My::NoNew->new();
	is $obj, $stub, 'inherited new is intercepted';

	restore_all();
};

# =================================================================
# Integration: combine with spy to record new() calls
# =================================================================

subtest 'intercept_new — combine with spy on new' => sub {
	intercept_new 'My::Service' => bless { stub => 1 }, 'My::Service';

	my $new_spy = spy 'My::Service::new';

	My::Service->new(a => 1);
	My::Service->new(b => 2);

	my @calls = $new_spy->();
	is scalar @calls, 2, 'spy records both constructor calls';
	is $calls[0][1], 'My::Service', 'invocant (class) captured by spy';

	restore_all();
};

# =================================================================
# Error cases
# =================================================================

subtest 'error: intercept_new with undef class' => sub {
	dies_ok { intercept_new(undef, bless {}, 'My::Service') }
		'undef class name croaks';
};

subtest 'error: intercept_new with empty-string class' => sub {
	dies_ok { intercept_new('', bless {}, 'My::Service') }
		'empty class name croaks';
};

subtest 'error: intercept_new with no factory argument' => sub {
	dies_ok { intercept_new('My::Service') }
		'missing factory argument croaks';
};

done_testing();
