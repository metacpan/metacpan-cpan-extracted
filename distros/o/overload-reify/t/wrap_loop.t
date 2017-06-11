#!perl

use Test::Lib;
use Test2::Bundle::Extended;

{
    package Parent;

    use overload '+=' => 'operator_add_assign';

    sub new { bless {}, shift }

    sub operator_add_assign { $_[0] }
}

{
    package Child;

    BEGIN {
        our @ISA = qw( Parent );
    }

    use overload::reify '+=';
    use Class::Method::Modifiers;
    use Carp;

    my $loop;

    before 'operator_add_assign' => sub {
        croak( "inifinite loop" ) if $loop++;
    }
}


ok ( lives {
    my$c1 = Child->new;
    $c1 += 2;
    },
    q[renaming method w/ same name doesn't cause infinite loop]
);


done_testing;
