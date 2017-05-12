#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

TODO:
- tests for DEMOLISH under multiple-inheritance
- test with %HAS values that need destroying

=cut

my $COLLECTOR;

{
    package Foo;
    use strict;
    use warnings;
    our @ISA = ('UNIVERSAL::Object');

    sub collect {
        my ($self, $stuff) = @_;
        push @$COLLECTOR => $stuff;
    }

    sub DEMOLISH {
        $_[0]->collect( 'Foo' );
    }

    package Bar;
    use strict;
    use warnings;
    our @ISA = ('Foo');

    sub DEMOLISH {
        $_[0]->collect( 'Bar' );
    }

    package Baz;
    use strict;
    use warnings;
    our @ISA = ('Bar');

    sub DEMOLISH {
        $_[0]->collect( 'Baz' );
    }
}

{
    $COLLECTOR = [];
    Foo->new;
    is_deeply($COLLECTOR, ['Foo'], '... got the expected collection');
}

{
    $COLLECTOR = [];
    Bar->new;
    is_deeply($COLLECTOR, ['Bar', 'Foo'], '... got the expected collection');
}

{
    $COLLECTOR = [];
    Baz->new;
    is_deeply($COLLECTOR, ['Baz', 'Bar', 'Foo'], '... got the expected collection');
};


