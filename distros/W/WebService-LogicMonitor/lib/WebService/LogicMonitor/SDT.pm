package WebService::LogicMonitor::SDT;

# ABSTRACT: A LogicMonitor Scheduled DownTime object

use v5.16.3;
use Moo;

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        startDateTime               => 'start_dt',
        endDateTime                 => 'end_dt',
        isEffective                 => 'is_effective',
        dataSourceInstanceGroupName => 'datesource_instance_group_name',
        dataSourceInstanceName      => 'datasource_instance_name',
        dataSourceName              => 'datasource_name',
        hostId                      => 'host_id',
        hostName                    => 'host_name',
        hostGroupName               => 'hostGroupName',
    );

    for my $key (keys %transform) {
        $args->{$transform{$key}} = delete $args->{$key} if $args->{$key};
    }

    return $args;
}

has id => (is => 'ro');    # int

has type => (is => 'rw');  # enum onetime|

has admin => (is => 'rw'); # str

has comment => (is => 'rw');    # str

has [qw/start_dt end_dt/] => (
    is     => 'rw',
    coerce => sub {
        my $h = shift;
        delete $h->{weekDay};
        return DateTime->new($h);
    },
);                              # datetime

has is_effective => (is => 'ro');    # bool

has category => (is => 'rw');        # { name => "HostSDT" },

# TODO some of these keys are not applicable depending on the category of SDT
has [qw/datasource_name datasource_instance_name datasource_instance_group_name/] => (is => 'rw');
has [qw/host_id host_name hostgroup_name/] => (is => 'rw');

# duration                      0,
# endHour                       0,
# endMinute                     0,
# hostDisplayedAs               "test1",
# hour                          0,
# minute                        0,
# monthDay                      0,
# sdtType                       1,
# weekDay                       1

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::SDT - A LogicMonitor Scheduled DownTime object

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
