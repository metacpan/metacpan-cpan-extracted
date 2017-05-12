#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

TODO:
- test for some failure conditions where BUILDARGS
  does not behave properly
    - returns something other then HASH ref
- test inherited custom BUILDARGS
    - chaining BUILDARGS methods along inheritance
- test under multiple inheritance
- test with %HAS values

=cut

{
    package Foo::NoInheritance;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub BUILDARGS {
        my ($class, $bar) = @_;
        return { foo => $bar }
    }

    package Foo::WithInheritance::NextMethod;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub BUILDARGS {
        my ($class, $bar) = @_;
        return $class->next::method( foo => $bar )
    }

    package Foo::WithInheritance::SuperCall;
    use strict;
    use warnings;
    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN { %HAS = (foo => sub { 'FOO' }) };

    sub BUILDARGS {
        my ($class, $bar) = @_;
        return $class->SUPER::BUILDARGS( foo => $bar )
    }
}

{
    my $o = Foo::NoInheritance->new( 'BAR' );
    isa_ok($o, 'Foo::NoInheritance');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');
}

{
    my $o = Foo::WithInheritance::NextMethod->new( 'BAR' );
    isa_ok($o, 'Foo::WithInheritance::NextMethod');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');
}

{
    my $o = Foo::WithInheritance::SuperCall->new( 'BAR' );
    isa_ok($o, 'Foo::WithInheritance::SuperCall');
    isa_ok($o, 'UNIVERSAL::Object');

    ok(exists $o->{foo}, '... got the expected slot');
    is($o->{foo}, 'BAR', '... the expected slot has the expected value');
}


