use v5.10.1;
use Test::Roo;
use Test::Fatal;
use DateTime;
use lib 't/lib';

with 'LogicMonitorTests';

has host => (is => 'ro', default => 'test1');

test 'get alerts' => sub {
    my $self = shift;

    my $alerts;

    is exception { $alerts = $self->lm->get_alerts }, undef,
      'got all the alerts';
    isa_ok $alerts, 'ARRAY';

    is exception { $alerts = $self->lm->get_alerts(host => $self->host) },
      undef, 'got alerts for one host';

  SKIP: {
        skip 'There are no alerts for this test host', 1 unless $alerts;
        isa_ok $alerts, 'ARRAY';

    }
};

# test 'get alerts last month' => sub {
#     my $self = shift;

#     my $cur_dt = DateTime->now;

#     # I am assuming there will always be enough data for the previous month
#     my $last_month_start_dt =
#       $cur_dt->clone->set_day(1)->subtract(months => 1)->subtract(days => 1)
#       ->set_minute(0)->set_hour(0)->set_second(0)->add(days => 1);

#     my $last_month_end_dt =
#       $cur_dt->clone->set_day(1)->add(months => 1)->subtract(days => 1)
#       ->set_minute(0)->set_hour(0)->set_second(0)->subtract(months => 1);

#     diag
#       "Getting records for one month: $last_month_start_dt - $last_month_end_dt";

#     my $alerts;
#     is exception {
#         $alerts = $self->lm->get_alerts(
#             host  => $self->host,
#             start => $last_month_start_dt->epoch,
#             end   => $last_month_end_dt->epoch,
#           )
#     }, undef, 'got some alerts';
#     isa_ok $alerts, 'ARRAY';

# };

run_me;
done_testing;
