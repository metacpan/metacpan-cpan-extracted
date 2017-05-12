use v5.10.1;
use Test::Roo;
use Test::Fatal;
use DateTime;
use lib 't/lib';

with 'LogicMonitorTests';

has host       => (is => 'ro', default => 'test1');
has datasource => (is => 'ro', default => 'Ping');
has datapoint  => (is => 'ro', default => 'PingLossPercent');
has datapoint2 => (is => 'ro', default => 'sentpkts');

# valid datapoints for NetSNMPMem
has expected_datapoints => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        [sort qw/average maxrtt minrtt PingLossPercent recvdpkts sentpkts/];
    },
);

test 'get data now' => sub {
    my $self = shift;

    like(
        exception { $self->lm->get_data },
        qr/'host' is required/,
        'missing host',
    );

    like(
        exception { $self->lm->get_data(host => $self->host) },
        qr/Either 'datasource' or/,
        'missing datasource instance',
    );

    my $data;
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                period     => '2hrs',
            );
        },
        undef,
        'got some data',
    );

    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';
    isa_ok $data->values, 'HASH';
    isa_ok $data->values->{$self->datasource}, 'HASH';

    isa_ok $data->datapoints, 'ARRAY';
    is_deeply [sort @{$data->datapoints}],
      \@{$self->expected_datapoints}, 'Got all expected keys';
};

test 'get data one month' => sub {
    my $self = shift;

    my $cur_dt = DateTime->now;

    # I am assuming there will always be enough data for the previous month
    my $last_month_start_dt =
      $cur_dt->clone->set_day(1)->subtract(months => 1)->subtract(days => 1)
      ->set_minute(0)->set_hour(0)->set_second(0)->add(days => 1);

    my $last_month_end_dt =
      $cur_dt->clone->set_day(1)->add(months => 1)->subtract(days => 1)
      ->set_minute(0)->set_hour(0)->set_second(0)->subtract(months => 1);

    diag
      "Getting records for one month: $last_month_start_dt - $last_month_end_dt";

    my $data;
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                start      => $last_month_start_dt->epoch,
                end        => $last_month_end_dt->epoch,
            );
        },
        undef,
        'got some data',
    );

    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';

    # XXX data contains one entry per 12h40m
    my $dsi_values = $data->values->{$self->{datasource}};

    ok scalar keys %$dsi_values <= 61 && scalar keys %$dsi_values >= 59,
      '59 - 61 values in array';

};

test 'get data by period' => sub {
    my $self = shift;

    my $data;
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                period     => '1days',
            );
        },
        undef,
        'got 1 day of data',
    );
    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';

    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                period     => '4hours',
            );
        },
        undef,
        'got 4 hours of data',
    );
    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';
};

test 'get only one datapoint' => sub {
    my $self = shift;

    like(
        exception {
            $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                datapoint  => $self->datapoint,
            );
        },
        qr/'datapoint' must be an arrayref/,
        'Bad args',
    );

    my $data;
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                period     => '2hrs',
                datapoint  => [$self->datapoint],
            );
        },
        undef,
        'got some data',
    );

    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';
    is scalar @{$data->datapoints}, 1, '1 value in array';

    my $dsi_values = $data->values->{$self->{datasource}};
    my $rand_value =
      $dsi_values->{[keys %$dsi_values]->[int rand keys %$dsi_values]};
    is keys %$rand_value, 1, 'Got one keys...';
    ok exists $rand_value->{$self->datapoint}, '... one matches';
};

test 'get two datapoints' => sub {
    my $self = shift;

    my $data;
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                period     => '2hrs',
                datapoint  => [$self->datapoint, $self->datapoint2],
            );
        },
        undef,
        'got some data',
    );

    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';
    is scalar @{$data->datapoints}, 2, '2 values in array';

    my $dsi_values = $data->values->{$self->{datasource}};
    my $rand_value =
      $dsi_values->{[keys %$dsi_values]->[int rand keys %$dsi_values]};
    is keys %$rand_value, 2, 'Got two keys...';
    ok exists $rand_value->{$self->datapoint}, '... two matches';
};

test 'get aggregated datapoint' => sub {
    my $self = shift;

    my ($data, $min, $avg, $max);
    is(
        exception {
            $data = $self->lm->get_data(
                host       => $self->host,
                datasource => $self->datasource,
                datapoint  => [$self->datapoint],
                aggregate  => 'AVERAGE',
                period     => '1weeks'
              )
        },
        undef,
        'got 1 week average',
    );
    isa_ok $data, 'WebService::LogicMonitor::DataSourceData';

    # TODO need a test host with some real values

    # is exception {
    #     $data = $self->lm->get_data(
    #         host      => $self->host,
    #         dsi       => $self->dsi,
    #         datapoint => [$self->datapoint],
    #         aggregate => 'MAX',
    #         period    => '1weeks'
    #       )
    # }, undef, 'got 1 week max';
    # isa_ok $data, 'ARRAY';
    # $max = $data->[0]->{values}->{$self->datapoint};
    #
    # is exception {
    #     $data = $self->lm->get_data(
    #         host      => $self->host,
    #         dsi       => $self->dsi,
    #         datapoint => [$self->datapoint],
    #         aggregate => 'MIN',
    #         period    => '1weeks'
    #       )
    # }, undef, 'got 1 week min';
    # isa_ok $data, 'ARRAY';
    # $min = $data->[0]->{values}->{$self->datapoint};

    #   cmp_ok $min, '<', $avg, 'Numbers seem sane...';
    #   cmp_ok $avg, '<', $max, 'Numbers seem sane...';
};

run_me;
done_testing;
