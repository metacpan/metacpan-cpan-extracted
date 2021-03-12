use Test2::V0;

package RoleX {
    use exact 'role';

    class_has r_class_has => 'RoleX class_has';
    has       r_has       => 'RoleX has';
}

package ClassA {
    use exact 'class';

    with 'RoleX';

    class_has c_class_has => 'ClassA class_has';
    has       c_has       => 'ClassA has';
}

package ClassB {
    use exact 'class';

    with 'RoleX';

    class_has c_class_has => 'ClassB class_has';
    has       c_has       => 'ClassB has';
}

package ClassA_RoleLast {
    use exact 'class';

    class_has c_class_has => 'ClassA class_has';
    has       c_has       => 'ClassA has';

    with 'RoleX';
}

package ClassB_RoleLast {
    use exact 'class';

    class_has c_class_has => 'ClassB class_has';
    has       c_has       => 'ClassB has';

    with 'RoleX';
}

package ClassA_NoRole {
    use exact 'class';

    class_has c_class_has => 'ClassA class_has';
    has       c_has       => 'ClassA has';
}

package ClassB_NoRole {
    use exact 'class';

    class_has c_class_has => 'ClassB class_has';
    has       c_has       => 'ClassB has';
}

my $compiled_data = join( "\n",
    'ClassA class_has',
    'ClassA has',
    'ClassA class_has',
    'ClassA has',
    'ClassB class_has',
    'ClassB has',
    'ClassB class_has',
    'ClassB has',
    'RoleX class_has',
    'RoleX has',
    'RoleX class_has',
    'RoleX has',
    'RoleX class_has',
    'RoleX has',
    'RoleX class_has',
    'RoleX has',
);

my $changed_data = join( "\n",
    'NEW VALUE for $class_a_1->c_class_has',
    'NEW VALUE for $class_a_1->c_has',
    'NEW VALUE for $class_a_1->c_class_has',
    'ClassA has',
    'ClassB class_has',
    'ClassB has',
    'ClassB class_has',
    'ClassB has',
    'NEW VALUE for $class_a_1->r_class_has',
    'NEW VALUE for $class_a_1->r_has',
    'NEW VALUE for $class_a_1->r_class_has',
    'RoleX has',
    'RoleX class_has',
    'RoleX has',
    'RoleX class_has',
    'RoleX has',
);

my ( $class_a_1, $class_a_2, $class_b_1, $class_b_2 );

sub report {
    join( "\n",
        $class_a_1->c_class_has,
        $class_a_1->c_has,
        $class_a_2->c_class_has,
        $class_a_2->c_has,
        $class_b_1->c_class_has,
        $class_b_1->c_has,
        $class_b_2->c_class_has,
        $class_b_2->c_has,
        $class_a_1->r_class_has,
        $class_a_1->r_has,
        $class_a_2->r_class_has,
        $class_a_2->r_has,
        $class_b_1->r_class_has,
        $class_b_1->r_has,
        $class_b_2->r_class_has,
        $class_b_2->r_has,
    );
}

sub change_test {
    is( report, $compiled_data, $_[0] . ' compiled data' );

    $class_a_1->c_has('NEW VALUE for $class_a_1->c_has');
    $class_a_1->c_class_has('NEW VALUE for $class_a_1->c_class_has');
    $class_a_1->r_has('NEW VALUE for $class_a_1->r_has');
    $class_a_1->r_class_has('NEW VALUE for $class_a_1->r_class_has');

    is( report, $changed_data, $_[0] . ' changed data' );
}

$class_a_1 = ClassA->new;
$class_a_2 = ClassA->new;
$class_b_1 = ClassB->new;
$class_b_2 = ClassB->new;

change_test('standard');

$class_a_1 = ClassA_RoleLast->new;
$class_a_2 = ClassA_RoleLast->new;
$class_b_1 = ClassB_RoleLast->new;
$class_b_2 = ClassB_RoleLast->new;

change_test('role last');

$class_a_1 = ClassA_NoRole->new->with_roles('RoleX');
$class_a_2 = ClassA_NoRole->new->with_roles('RoleX');
$class_b_1 = ClassB_NoRole->new->with_roles('RoleX');
$class_b_2 = ClassB_NoRole->new->with_roles('RoleX');

change_test('with roles');

done_testing;
