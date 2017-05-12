use lib 't/lib';
use Test::Roo;
use Test::Fatal;

with 'LogicMonitorTests';

test 'get all groups' => sub {
    my $self = shift;

    my $hosts;
    is(
        exception { $hosts = $self->lm->get_groups; },
        undef, 'Retrieved host groups',
    );

    isa_ok $hosts, 'ARRAY';
    isa_ok $hosts->[0], 'WebService::LogicMonitor::Group';
    my $num_hosts = scalar @$hosts;

    is(
        exception { $hosts = $self->lm->get_groups(name => 'Testing'); },
        undef, 'Retrieved host groups with string filter',
    );

    isa_ok $hosts, 'ARRAY';
    ok scalar @$hosts < $num_hosts,
      'The filtered array is smaller than all hosts';
    isa_ok $hosts->[0], 'WebService::LogicMonitor::Group';

    ok my $props = $hosts->[0]->properties, 'Got properties';
    isa_ok $props, 'HASH';

    is(
        exception { $hosts = $self->lm->get_groups(name => qr/sti/) },
        undef, 'Retrieved host groups with regexp filter',
    );

};

test 'get child host groups' => sub {
    my $self   = shift;
    my $groups = $self->lm->get_groups(name => 'Testing');
    my $g      = shift @$groups;

    my $children;
    is(
        exception { $children = $g->children },
        undef, 'Retrieved host group children',
    );

    isa_ok $children, 'ARRAY';
    note 'Fragile tests ahead!';
    isa_ok $children->[0], 'WebService::LogicMonitor::Group';
    isa_ok $children->[1], 'WebService::LogicMonitor::Host';
};

test 'update host group' => sub {
    my $self = shift;

    my $g;

    is(
        exception {
            my $groups = $self->lm->get_groups(name => 'Testing');
            $g = shift @$groups;
        },
        undef,
        'Retrieved host groups',
    );

    ok !exists $g->properties->{testproperty}, 'testproperty does not exist';
    my $time = time;
    ok $g->properties->{testproperty} = $time, 'set testproperty';

    is(exception { $g->update }, undef, 'Updated host group');

    # get a fresh copy
    $g = undef;

    is(
        exception {
            my $groups = $self->lm->get_groups(name => 'Testing');
            $g = shift @$groups;
        },
        undef,
        'Retrieved host groups',
    );

    ok exists $g->properties->{testproperty}, 'testproperty does exist';
    is $g->properties->{testproperty}, $time, 'timestamp matches';

    ok delete $g->properties->{testproperty}, 'deleted testproperty';
    is(exception { $g->update }, undef, 'Updated host group again');

    # get a fresh copy
    $g = undef;

    is(
        exception {
            my $groups = $self->lm->get_groups(name => 'Testing');
            $g = shift @$groups;
        },
        undef,
        'Retrieved host groups',
    );

    ok !exists $g->properties->{testproperty},
      'testproperty does NOT exist again';
};

run_me;
done_testing;
