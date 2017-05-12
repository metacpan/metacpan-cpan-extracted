#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

TODO:
- test calling ->new on an instance
    - test it under inheritance
- test overriding ->new
    - test that it bypasses the BLESS, CREATE, BUILD, etc.
- do more elaborate tests with %HAS

=cut

{
    package Foo;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };
}

{
    my $o = UNIVERSAL::Object->new( foo => 'BAR' );
    isa_ok($o, 'UNIVERSAL::Object');

    ok(!exists $o->{foo}, '... got the expected lack of a slot');
}

{
    my $o = Foo->new( foo => 'BAR' );
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');
}

{
    my $o = Foo->new;
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'FOO', '... the expected slot has the expected value');
}


