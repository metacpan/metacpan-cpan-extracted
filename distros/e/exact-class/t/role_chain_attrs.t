use Test2::V0;

package Deep {
    use exact -role;
    has 'remote';
    class_has 'remote_class' => 13;
}

package Middle {
    use exact -role;
    with 'Deep';
}

package Direct {
    use exact -class;
    with 'Deep';
    has 'local';
    class_has 'local_class' => 14;
}

package Indirect {
    use exact -class;
    with 'Middle';
    has 'local';
    class_has 'local_class' => 15;
}

my $direct   = Direct->new( remote => 42 );
my $indirect = Indirect->new( remote => 42 );

is( $direct->remote, 42, 'direct remote attr set-able' );
is( $indirect->remote, 42, 'indirect remote attr set-able' );

my $direct_set_0 = Direct->new->remote(42);
my $direct_set_1 = Direct->new->remote(1138);

ok(
    ( $direct_set_0->remote == 42 and $direct_set_1->remote == 1138 ),
    'multiple direct remote attr do not bleed',
);

my $indirect_set_0 = Indirect->new->remote(42);
my $indirect_set_1 = Indirect->new->remote(1138);

ok(
    ( $indirect_set_0->remote == 42 and $indirect_set_1->remote == 1138 ),
    'multiple indirect remote attr do not bleed',
);

my $direct_class = Direct->new( remote_class => 142 );
my $indirect_class = Indirect->new( remote_class => 143 );

is( $direct_class->remote_class, 142, 'direct class remote class' );
is( $indirect_class->remote_class, 143, 'indirect class remote class' );

my $j_obj = Direct->new->remote_class(144);
my $k_obj = Direct->new->remote_class(145);

is( $direct_class->remote_class, 145, 'direct class remote class' );
is( $indirect_class->remote_class, 143, 'indirect class remote class' );
is( $j_obj->remote_class, 145, 'j obj remote class' );
is( $k_obj->remote_class, 145, 'k obj remote class' );

my $x_obj = Indirect->new->remote_class(146);
my $y_obj = Indirect->new->remote_class(147);

is( $direct_class->remote_class, 145, 'direct class remote class' );
is( $indirect_class->remote_class, 147, 'indirect class remote class' );
is( $j_obj->remote_class, 145, 'j obj remote class' );
is( $k_obj->remote_class, 145, 'k obj remote class' );
is( $x_obj->remote_class, 147, 'x obj remote class' );
is( $y_obj->remote_class, 147, 'y obj remote class' );

done_testing;
