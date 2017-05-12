use lib 't/lib';
use Test::Fatal;
use Test::Deep;
use Test::Roo;
use String::Random 'random_string';

with 'LogicMonitorTests';

has instance_keys => (
    is      => 'ro',
    default => sub {
        [
            sort
              qw/alertEnable dataSourceDisplayedAs dataSourceId description discoveryInstanceId enabled hasAlert hasGraph hasUnConfirmedAlert hostDataSourceId hostId id name wildalias wildvalue wildvalue2/
        ];
    },
);

test 'one host' => sub {
    my $self = shift;

    like(
        exception { $self->lm->get_host; },
        qr/Missing displayname/,
        'Fails without a displayname',
    );

    my $host;
    is(
        exception { $host = $self->lm->get_host('mx-spam1'); },
        undef, 'Retrieved host',
    );

    isa_ok $host, 'WebService::LogicMonitor::Host';
    is $host->name,           'mx-spam1', 'Name matches';
    is $host->type,           'HOST',     'Type is HOST';
    isa_ok $host->created_on, 'DateTime', 'created_on is a datetime object';

};

test 'multiple hosts by group' => sub {
    my $self = shift;

    like(
        exception { $self->lm->get_hosts; },
        qr/Missing hostgroupid/,
        'Fails without a hostgroupid',
    );

    my $hosts;
    is(
        exception { $hosts = $self->lm->get_hosts(12); },
        undef, 'Retrieved host list',
    );

    isa_ok $hosts, 'ARRAY';
    isa_ok $hosts->[0], 'WebService::LogicMonitor::Host';

    my $hostgroup;
    is(
        exception { ($hosts, $hostgroup) = $self->lm->get_hosts(12); },
        undef, 'Retrieved host list',
    );

    isa_ok $hosts, 'ARRAY';
    isa_ok $hosts->[0], 'WebService::LogicMonitor::Host';
    isa_ok $hostgroup, 'HASH';
};

# XXX this takes a really long time
# test 'all hosts' => sub {
#     my $self = shift;

#     my $hosts;
#     is(
#         exception { $hosts = $self->lm->get_all_hosts; },
#         undef, 'Retrieved host list',
#     );

#     isa_ok $hosts, 'ARRAY';
# };

test 'get data source instances' => sub {
    my $self = shift;

    my $host = $self->lm->get_host('test1');

    like(
        exception { $host->get_datasource_instances(); },
        qr/Missing datasource name/,
        'Fails without a datasource name',
    );

    like(
        exception { $host->get_datasource_instances('ArgleBargle'); },
        qr/^Failed call to "getDataSourceInstances": \[600\]/,
        'No such datasurce',
    );

    my $instances;
    is(
        exception {
            $instances = $host->get_datasource_instances('Ping');
        },
        undef,
        'Retrieved instance list',
    );

    isa_ok $instances, 'ARRAY';
    isa_ok $instances->[0], 'WebService::LogicMonitor::DataSourceInstance';
};

test 'update a host' => sub {
    my $self = shift;

    my $host;
    is(
        exception { $host = $self->lm->get_host('test1'); },
        undef, 'Retrieved host',
    );

    # like(
    #     exception { $->update_host; },
    #     qr/Missing host_id/,
    #     'Fails without a host_id',
    # );

    $host->add_system_category('channelserver');
    is(exception { $host->update }, undef, 'Updated hosts',);

    #$host->{autoPropsAssignedOn} = time;

    # is(
    #     exception { $host2 = $self->lm->get_host('test1'); },
    #     undef, 'Retrieved host',
    # );

    #delete $host->{autoPropsUpdatedOn};
    #delete $host2->{autoPropsUpdatedOn};

    # use Data::Printer;
    # p $host;
    # p $host2;

    # cmp_deeply $host, $host2, 'Old host and new host match';
};

test 'add and remove host' => sub {
    my $self = shift;

    my $hostname = random_string('cccccccccccc');

    my $host;
    is(
        exception {
            $host = WebService::LogicMonitor::Host->new(
                host_name    => "$hostname.example.com",
                displayed_as => $hostname,
                agent_id => 11,    # XXX we need a dedicated test collector!
                link => "http://$hostname.example.com",
            );
        },
        undef,
        'Created a new host object',
    );

    is(exception { $host->create },
        undef, "New host $hostname created in LoMo");

    my $new_host = $self->lm->get_host($hostname);
    is $new_host->link, "http://$hostname.example.com",
      "New host $hostname has correct link";

    is(exception { $new_host->delete },
        undef, "New host $hostname deleted from LoMo");
    like(
        exception { $self->lm->get_host($hostname); },
        qr/^Failed call to "getHost": \[1007\] No such host/,
        "Host $hostname is definitely gone"
    );
};

run_me;
done_testing;
