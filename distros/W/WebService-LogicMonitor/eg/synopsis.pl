use v5.20;
use warnings;
use Try::Tiny;
use WebService::LogicMonitor;
use experimental 'signatures';

# find a hostgroup by name, iterate through its child groups
# and check the status of a datasource instance

my $lm = WebService::LogicMonitor->new(
    username => $ENV{LOGICMONITOR_USER},
    password => $ENV{LOGICMONITOR_PASS},
    company  => $ENV{LOGICMONITOR_COMPANY},
);

my $top_group_name = shift || die "What group?\n";
my $datasource     = shift || 'Ping';

sub recurse_group($group) {
    foreach my $entity (@{$group->children}) {
        if ($entity->is_group) {
            say 'GROUP: ' . $entity->name;
            recurse_group($entity);
        } elsif ($entity->is_host) {
            say '  HOST: ' . $entity->host_name;
            my $instances = try {
                $entity->get_datasource_instances($datasource);
            }
            catch {
                say "Failed to retrieve data source instances: " . $_;
                next;
            };

            next unless $instances;

            # assume only one instance
            my $instance = shift @$instances;

            say '    datasource status: '
              . ($instance->enabled ? 'enabled' : 'disabled');
            say '    alert status: '
              . ($instance->alert_enable ? 'enabled' : 'disabled');
        }

    }
}

my $groups = $lm->get_groups(name => $top_group_name);
recurse_group(shift @$groups);
