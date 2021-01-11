use Test2::V0;

package Thing {
    use exact 'class';

    has name => undef;
    has data => undef;

    sub create {
        my ($self) = @_;
        $self->data( { $self->name => 42 } );
        return $self;
    }

    sub fetch {
        my ($self) = @_;
        return $self->data;
    }
}

package Thing::Role {
    use exact 'role';

    has name2 => undef;
    has data2 => undef;

    sub create2 {
        my ($self) = @_;
        $self->data2( { $self->name2 => 43 } );
        return $self;
    }

    sub fetch2 {
        my ($self) = @_;
        return $self->data2;
    }
}

package Thing::SubClassA {
    BEGIN {
        our @ISA;
        push @ISA, 'Thing';
    }

    use exact 'class';

    with 'Thing::Role';

    has name  => 'a';
    has name2 => 'a2';
}

package Thing::SubClassB {
    BEGIN {
        our @ISA;
        push @ISA, 'Thing';
    }

    use exact 'class';

    with 'Thing::Role';

    has name  => 'b';
    has name2 => 'b2';
}

my $obj;

ok(
    lives {
        $obj->{a} = Thing::SubClassA->new->create;
        $obj->{b} = Thing::SubClassB->new->create;
    },
    'object instantiation lives',
) or note $@;

is( $obj->{a}->fetch->{a}, 42, 'inheritted values descend' );

ok(
    lives {
        $obj->{a2} = Thing::SubClassA->new->create2;
        $obj->{b2} = Thing::SubClassB->new->create2;
    },
    'object instantiation with roles lives',
) or note $@;

is( $obj->{a2}->fetch2->{a2}, 43, 'inheritted values with roles descend' );

done_testing;
