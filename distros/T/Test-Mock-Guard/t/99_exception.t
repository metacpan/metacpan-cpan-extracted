use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;

sub new { bless {}, shift }
sub foo { 'foo' }

package main;

{
    note 'empty';
    local $@;
    eval { mock_guard() };
    like $@, qr/must be specified key-value pair/;
}

{
    note 'not pair';
    local $@;
    eval { mock_guard('Foo') };
    like $@, qr/must be specified key-value pai/;
}

{
    note 'module not found';
    local $@;
    eval { mock_guard('__THIS__::__MODULE__::__IS__::__DUMMY__' => {}) };
    like $@, qr/Can't locate __THIS__/;
}

{
    note 'class name undefined';
    local $@;
    eval { mock_guard(undef, {}) };
    like $@, qr/Usage: mock_guard/;
}

{
    note 'method_defs is not hasref';
    local $@;
    eval { mock_guard('Foo::Bar', []) };
    like $@, qr/Usage: mock_guard/;
}

{
    note 'empty for reset()';
    local $@;
    my $guard = mock_guard('Some::Class' => { foo => 'bar' });
    eval { $guard->reset() };
    like $@, qr/must be specified key-value pair/;
}

{
    note 'not pair for reset()';
    local $@;
    my $guard = mock_guard('Some::Class' => { foo => 'bar' });
    eval { $guard->reset('AAA') };
    like $@, qr/must be specified key-value pair/;
}

{
    note 'class name undefined for reset()';
    local $@;
    my $guard = mock_guard('Some::Class' => { foo => 'bar' });
    eval { $guard->reset(undef, []) };
    like $@, qr/Usage: \$guard->reset\(/;
}

{
    note 'methods s note arrayref reset()';
    local $@;
    my $guard = mock_guard('Some::Class' => { foo => 'bar' });
    eval { $guard->reset('Some::Class', {}) };
    like $@, qr/Usage: \$guard->reset\(/;
}

done_testing;
