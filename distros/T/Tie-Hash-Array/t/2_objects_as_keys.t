#!perl -Tw

use strict;
use Test::More tests => 4;

{
    package my::Foo;
    use overload '""' => 'as_string', 'cmp' => 'compare';
    sub new {
        my($package, $value) = @_;
        bless \$value, $package;
    }
    sub as_string { ${+shift} }
    sub compare {
        my($self, $other, $swapped) = @_;
        ($other, $self) = ($self, $other) if $swapped;
        for ($self, $other) { $_ = $_->as_string if ref }
        $self cmp $other
    }
}

BEGIN { use_ok 'Tie::Hash::Array' }					# test

tie my %hash, 'Tie::Hash::Array';
isa_ok tied %hash, 'Tie::Hash::Array', 'tied %hash';			# test

my $foo = new my::Foo 'foo';
$hash{$foo} = 'FOO';
$hash{bar} = 'BAR';
while (my($key, $value) = each %hash) {
    next unless $value eq 'FOO';
    isa_ok $key, 'my::Foo', 'key';					# test
    can_ok $key, 'as_string';						# test
}
