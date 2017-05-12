package WebService::Site24x7::Reports;

use Moo;

has client => (is => 'rw', required => 1, handles => [qw/get/]);

sub log_reports {
    my ($self, $monitor_id, %params) = @_;
    return $self->get(
        "/reports/log_reports/${monitor_id}",
        \%params,
    )->data;
}

sub performance {
    my ($self, $monitor_id, %params) = @_;
    return $self->get(
        "/reports/performance/${monitor_id}",
        \%params,
    )->data;
}

1;
