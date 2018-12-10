use Test::More;
use lib 't/lib/oo';
use_ok 'Person';

my $p = new_ok Person => [ lastname  => "Doe" ];
isa_ok $p, 'Person';
can_ok $p, 'lastname';

eval {
    is $p->lastname , 'Doe'  , '->lastname  from constructor';
    ok +( not defined $p->firstname ) =>
       q( not defined $p->firstname );
};

eval q( $p->firstname //= 'John' );
is $p->firstname, 'John' , '->firstname from //=';
eval q( $p->firstname //= 'Peter' );
is $p->firstname, 'John' , '->firstname existed';
eval q( $p->age = 42 );
is $p->age, 42 , '->age = 42';
eval q( $p->age++ );
is $p->age, 43 , '->age = 43';

done_testing;
