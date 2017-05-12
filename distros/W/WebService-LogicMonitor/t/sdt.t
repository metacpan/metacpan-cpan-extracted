use v5.10.1;
use Test::Roo;
use lib 't/lib';

use DateTime;
use Test::Fatal;
use Test::Deep;

with 'LogicMonitorTests';

test sdt => sub {
    my $self = shift;

    like(
        exception { $self->lm->get_sdts('hostGroupId') },
        qr/Can not specify a key/,
        'Fails with a key but no id',
    );

    my $sdts;
    is(exception { $sdts = $self->lm->get_sdts },
        undef, 'Retrieved all sdts',);

    isa_ok $sdts, 'ARRAY';

    # There should never be any sdts set at this point but there may be
    # so store the current number
    my $num_existing_sdts = scalar @$sdts;
    if ($num_existing_sdts > 0) {
        warn 'There are existing SDTs on this acccount which may affect tests';
    }

    like(
        exception { $self->lm->set_sdt(Host => 'test1') },
        qr/^Missing start/,
        'Failed to set sdt without params',
    );

    my $start_dt = DateTime->now(time_zone => 'UTC');
    my $end_dt = $start_dt->clone->add(days => 1);

    my $res;

    is(
        exception {
            $res = $self->lm->set_sdt(
                Host    => 'test1',
                type    => 1,
                start   => $start_dt,
                end     => $end_dt,
                comment => ('Test one day SDT ' . time),
              )
        },
        undef,
        'Set SDT for host',
    );

    is(exception { $sdts = $self->lm->get_sdts },
        undef, 'Retrieved all sdts',);

    isa_ok $sdts, 'ARRAY';
    is scalar @$sdts, $num_existing_sdts + 1,
      'Array has more one entry than it did before';

    my $sdt = pop @$sdts;
    isa_ok $sdt, 'WebService::LogicMonitor::SDT';
    is $sdt->category->{name}, 'HostSDT', 'Category is HostSDT';
    ok $sdt->is_effective, 'SDT is currently in effect';
};

test 'quick sdt' => sub {
    my $self = shift;
    my $sdt;

    is(
        exception {
            $sdt = $self->lm->set_quick_sdt(
                Host    => 'test1',
                minutes => 2,
                type    => 1,
                comment => ('Quick add 2 hour sdt ' . time),
              )
        },
        undef,
        'Set quick SDT for host',
    );

    isa_ok $sdt, 'WebService::LogicMonitor::SDT';
    is $sdt->category->{name}, 'HostSDT', 'Category is HostSDT';
    ok $sdt->is_effective, 'SDT is currently in effect';
};

run_me;
done_testing;
