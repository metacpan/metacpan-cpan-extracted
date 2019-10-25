use Test::Most tests => 6;

use_ok('exact');

package Parent {
    use exact;
}

package Child {
    use exact;
}

BEGIN {
    $INC{ $_ . '.pm'} = 1 for qw( Parent Child );
}

sub child_parents {
    no strict 'refs';
    return join( ' | ', @{"Child::ISA"} ) || '';
}

is( child_parents(), '', 'no initial relationship' );
lives_ok( sub { exact->add_isa( qw( Parent Child ) ) }, 'add isa Parent Child' );
is( child_parents(), 'Parent', 'parent/child relationship' );
lives_ok( sub { exact->add_isa( qw( Parent Child ) ) }, 'add isa Parent Child again' );
is( child_parents(), 'Parent', 'parent/child relationship unchanged' );
