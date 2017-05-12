#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

TODO:
- test for some failure conditions where CREATE
  does not behave properly, ex:
    - returning unblessed instance
    - not passing the prototype to next::method
- test using SUPER::CREATE as well
- test inheriting custom CREATE method
    - chaining CREATE methods along inheritance
- test under multiple inheritance
- test with %HAS values

=cut

{
    package Foo;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub CREATE {
        my ($class, $proto) = @_;
        $proto->{foo} = 'BAR';
        return $class->next::method( $proto );
    }
}

{
    my $o = Foo->new;
    isa_ok($o, 'Foo');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');
}


