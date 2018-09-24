#!perl

use strict;
use warnings;

use lib '../../lib';

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object::Immutable');
}

{
    {
        package My::ArrayInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { +[] }
        sub CREATE { $_[0]->REPR }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::ArrayInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::ArrayInstance::Test');

    $@ = undef;
    eval { $instance->[100] = 10 };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');
}

{
    {
        package My::ScalarInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { \(my $r = 0) }
        sub CREATE { $_[0]->REPR }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::ScalarInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::ScalarInstance::Test');

    $@ = undef;
    eval { $$instance++ };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');
}

{
    {
        package My::RefInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { \(my $r = []) }
        sub CREATE { $_[0]->REPR }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::RefInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::RefInstance::Test');

    $@ = undef;
    eval { $$instance = {} };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');
}

{
    {
        package My::CodeInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { sub { 10 } }
        sub CREATE { $_[0]->REPR }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::CodeInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::CodeInstance::Test');

    # NOTE: no way to alter a CODE ref, so no need to test this
    # but we can see that it behaves as we expect ...

    $@ = undef;
    my $result = eval { $instance->() };
    ok(!$@, '... got the expected (lack of) error');
    is($result, 10, '... got the expected value');
}

{
    {
        package My::RegExpInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        sub REPR   { qr// }
        sub CREATE { $_[0]->REPR }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::RegExpInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::RegExpInstance::Test');
}

{
    {
        package My::OverloadedInstance::Test;

        use strict;
        use warnings;

        our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object::Immutable') }

        use overload '""' => 'to_string';

        sub REPR   { +{} }
        sub CREATE { $_[0]->REPR }

        sub to_string { __PACKAGE__.'::<<>>' }
    }

    my $instance;

    $@ = undef;
    eval { $instance = My::OverloadedInstance::Test->new };
    ok(!$@, '... got lack of error');

    isa_ok($instance, 'My::OverloadedInstance::Test');
}


