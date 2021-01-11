use Test2::V0;
use exact;

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
ok( lives { exact->add_isa( qw( Parent Child ) ) }, 'add isa Parent Child' ) or note $@;
is( child_parents(), 'Parent', 'parent/child relationship' );
ok( lives { exact->add_isa( qw( Parent Child ) ) }, 'add isa Parent Child again' ) or note $@;
is( child_parents(), 'Parent', 'parent/child relationship unchanged' );

done_testing;
