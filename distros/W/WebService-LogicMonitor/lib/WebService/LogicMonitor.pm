package WebService::LogicMonitor;

our $VERSION = '0.153170';

# ABSTRACT: Interact with LogicMonitor's API

use v5.16.3;    # minimum for CentOS 7
use autodie;
use Carp;
use DateTime;
use LWP::UserAgent;
use JSON;
use List::Util 'first';
use List::MoreUtils 'zip';
use Log::Any qw/$log/;
use URI::QueryParam;
use URI;
use Moo;

with 'Role::Singleton::New';

sub BUILD {

    # After new is done we turn it into a singleton. Any furrther call to new
    # will return the same instance
    return $_[0]->turn_new_into_singleton;
}


has [qw/password username company/] => (
    is       => 'ro',
    required => 1,
    isa      => sub { die 'must be defined' unless defined $_[0] },
);

has [qw/_base_url _auth_hash _ua/] => (is => 'lazy');

sub _build__base_url {
    my $self = shift;
    return URI->new(sprintf 'https://%s.logicmonitor.com/santaba/rpc',
        $self->company);
}

sub _build__auth_hash {
    my $self = shift;
    return {
        c => $self->company,
        u => $self->username,
        p => $self->password
    };
}

sub _build__ua {
    my $self = shift;
    return LWP::UserAgent->new(
        timeout => 10,
        agent   => __PACKAGE__ . "/$VERSION",
    );
}

sub _get_uri {
    my ($self, $method) = @_;

    my $uri = $self->_base_url->clone;
    $uri->path_segments($uri->path_segments, $method);
    $uri->query_form_hash($self->_auth_hash);
    $log->debug('URI: ' . $uri->path_query);
    return $uri;
}

sub _http_get {
    my ($self, $method) = (shift, shift);

    my $params;

    if (ref $_[0]) {
        $params = shift;
    } else {
        my %hash = @_;
        $params = \%hash;
    }

    my $uri = $self->_get_uri($method);

    foreach my $p (keys %$params) {
        $uri->query_param_append($p, $params->{$p});
    }

    $log->debug('Generated URI: ' . $uri->path_query);

    my $res = $self->_ua->get($uri);
    if (!$res->is_success) {
        croak sprintf("HTTP error! %d - %s\n", $res->code, $res->message);
    }

    my $res_decoded = decode_json $res->decoded_content;

    if ($res_decoded->{status} != 200) {
        croak(
            sprintf 'Failed call to "%s": [%s] %s',
            $method,
            $res_decoded->{status},
            $res_decoded->{errmsg});
    }

    return $res_decoded->{data};
}


sub get_escalation_chains {
    my $self = shift;

    my $data = $self->_http_get('getEscalationChains');

    require WebService::LogicMonitor::EscalationChain;

    my @chains;
    foreach my $chain (@$data) {
        push @chains, WebService::LogicMonitor::EscalationChain->new($chain);
    }

    return \@chains;
}


# TODO name or id
sub get_escalation_chain_by_name {
    my ($self, $name) = @_;

    my $chains = $self->get_escalation_chains;

    my $chain = first { $_->{name} eq $name } @$chains;
    return $chain;
}


sub get_accounts {
    my $self = shift;

    my $data = $self->_http_get('getAccounts');

    require WebService::LogicMonitor::Account;

    my @accounts;
    for (@$data) {
        push @accounts, WebService::LogicMonitor::Account->new($_);
    }

    return \@accounts;
}


sub get_account_by_email {
    my ($self, $email) = @_;

    croak "Missing email address" unless $email;

    my $accounts = $self->get_accounts;

    $log->debug("Searching for a user account with email address [$email]");

    my $account = first { $_->{email} =~ /$email/i } @$accounts;

    croak "Failed to find account with email <$email>" unless $account;

    return $account;
}


sub get_account_by_username {
    my ($self, $username) = @_;

    croak 'Missing username' unless $username;

    my $accounts = $self->get_accounts;

    $log->debug("Searching for a user account named [$username]");

    my $account = first { $_->{username} =~ /$username/i } @$accounts;

    croak "Failed to find account with username <$username>" unless $account;

    return $account;
}


# TODO why does this work with only host display name and not id?
sub get_data {
    my ($self, %args) = @_;

    # required params
    croak "'host' is required" unless $args{host};
    my %params = (host => $args{host},);

    if ($args{datasource_instance}) {
        $params{dataSourceInstance} = $args{datasource_instance};
    } elsif ($args{datasource}) {
        $params{dataSource} = $args{datasource};
    } else {
        croak "Either 'datasource' or 'datasource_instance' must be specified";
    }

    # optional params
    for (qw/start end aggregate period/) {
        $params{$_} = $args{$_} if $args{$_};
    }

    if ($args{datapoint}) {
        croak "'datapoint' must be an arrayref"
          unless ref $args{datapoint} eq 'ARRAY';

        for my $i (0 .. scalar @{$args{datapoint}} - 1) {
            $params{"dataPoint$i"} = $args{datapoint}->[$i];
        }
    }

    my $data = $self->_http_get('getData', %params);

    require WebService::LogicMonitor::DataSourceData;
    return WebService::LogicMonitor::DataSourceData->new($data);
}


sub get_alerts {
    my ($self, %args) = @_;

    my %transform = (
        ack_filter => 'ackFilter',
        filter_sdt => 'filterSDT',
        host_id    => 'hostId',
    );

    for my $key (keys %transform) {
        $args{$transform{$key}} = delete $args{$key}
          if exists $args{$key};
    }

    my $data = $self->_http_get('getAlerts', %args);

    return if $data->{total} == 0;

    require WebService::LogicMonitor::Group;
    require WebService::LogicMonitor::Alert;

    # convert host group hash to objects
    # do it here so we can make sure we only each create group once
    my %group_cache;
    for my $alert (@{$data->{alerts}}) {
        my @groups;
        for (@{$alert->{hostGroups}}) {
            if ($group_cache{$_->{id}}) {
                push @groups, $group_cache{$_->{id}};
            } else {
                my $g = WebService::LogicMonitor::Group->new($_);
                $group_cache{$_->{id}} = $g;
                push @groups, $g;
            }
        }
        $alert->{hostGroups} = \@groups;
    }

    my @alerts =
      map { WebService::LogicMonitor::Alert->new($_); } @{$data->{alerts}};

    return \@alerts;

}


sub add_host {
    my $self = shift;

    my %params = @_;

    require WebService::LogicMonitor::Host;
    return WebService::LogicMonitor::Host->new(\%params)->create;
}


sub delete_host {
    my ($self, $displayname) = @_;

    croak 'Missing displayname' unless $displayname;

    return $self->get_host($displayname)->delete;
}


sub get_host {
    my ($self, $displayname) = @_;

    croak "Missing displayname" unless $displayname;

    my $data = $self->_http_get('getHost', displayName => $displayname);

    require WebService::LogicMonitor::Host;
    return WebService::LogicMonitor::Host->new($data);
}


sub get_hosts {
    my ($self, $hostgroupid) = @_;

    croak "Missing hostgroupid" unless $hostgroupid;

    my $data = $self->_http_get('getHosts', hostGroupId => $hostgroupid);

    require WebService::LogicMonitor::Host;

    my @hosts;
    for (@{$data->{hosts}}) {
        push @hosts, WebService::LogicMonitor::Host->new($_);
    }

    return wantarray
      ? (\@hosts, $data->{hostgroup})
      : \@hosts;
}


sub get_all_hosts {
    return $_[0]->get_hosts(1);
}


sub get_groups {
    my ($self, $key, $value) = @_;

    $log->debug('Fetching a list of groups');

    my $data = $self->_http_get('getHostGroups');

    $log->debug('Number of hosts found: ' . scalar @$data);

    return unless scalar @$data > 0;

    if (defined $key && !defined $value) {
        die "Cannot search on $key without a value";
    }

    require WebService::LogicMonitor::Group;

    if (!defined $value) {
        my @groups = map { WebService::LogicMonitor::Group->new($_); } @$data;
        return \@groups;
    }

    my $filter_is_regexp;
    $log->debug("Filtering hosts on [$key] with [$value]");
    if (ref $value && ref $value eq 'Regexp') {
        $log->debug('Filter is a regexp');
        $filter_is_regexp = 1;
    } else {
        $log->debug('Filter is a string');
    }

    my @groups = map {
        die "This key is not valid: $key" unless $_->{$key};
        if ($filter_is_regexp ? $_->{$key} =~ $value : $_->{$key} eq $value) {
            WebService::LogicMonitor::Group->new($_);
        } else {
            ();
        }
    } @$data;

    $log->debug('Number of hosts after filter: ' . scalar @groups);

    return @groups ? \@groups : undef;
}


sub get_sdts {
    my ($self, $key, $id) = @_;

    my $data;
    if ($key) {
        defined $id or croak 'Can not specify a key without an id';
        $data = $self->_http_get('getSDTs', $key => $id);
    } else {
        $data = $self->_http_get('getSDTs');
    }

    require WebService::LogicMonitor::SDT;

    my @sdts;
    for (@$data) {
        push @sdts, WebService::LogicMonitor::SDT->new($_);
    }

    return \@sdts;
}


sub set_sdt {
    my ($self, $entity, $id, %args) = @_;

    # generate the method name and id key from entity
    my $method = 'set' . $entity . 'SDT';
    my $id_key;

    if ($id =~ /^\d+$/) {
        $id_key = lcfirst $entity . 'Id';
    } elsif ($entity eq 'Host') {
        $id_key = 'host';
    } else {
        croak "Invalid parameters - $entity => $id";
    }

    if (exists $args{type} && $args{type} != 1) {
        croak 'We only handle one-time SDTs right now';
    }

    $args{type} = 1;

    my $params = {
        $id_key => $id,
        type    => $args{type},
    };

    $params->{comment} = $args{comment} if exists $args{comment};

    croak 'Missing start time' unless $args{start};
    croak 'Missing end time'   unless $args{end};

    require DateTime::Format::ISO8601;

    my ($start_dt, $end_dt);
    if (!ref $args{start}) {
        $start_dt = DateTime::Format::ISO8601->parse_datetime($args{start});
    } else {
        $start_dt = $args{start};
    }

    if (!ref $args{end}) {
        $end_dt = DateTime::Format::ISO8601->parse_datetime($args{end});
    } else {
        $end_dt = $args{end};
    }

    # LoMo expects months to be 0..11
    @$params{(qw/year month day hour minute/)} = (
        $start_dt->year, ($start_dt->month - 1),
        $start_dt->day, $start_dt->hour, $start_dt->minute
    );

    @$params{(qw/endYear endMonth endDay endHour endMinute/)} = (
        $end_dt->year, ($end_dt->month - 1),
        $end_dt->day, $end_dt->hour, $end_dt->minute
    );

    my $res = $self->_http_get($method, $params);

    require WebService::LogicMonitor::SDT;
    return WebService::LogicMonitor::SDT->new($res);
}


sub set_quick_sdt {
    my $self   = shift;
    my $entity = shift;
    my $id     = shift;
    my $units  = shift;
    my $value  = shift;

    my $start_dt = DateTime->now(time_zone => 'UTC');
    my $end_dt = $start_dt->clone->add($units => $value);

    return $self->set_sdt(
        $entity => $id,
        start   => $start_dt,
        end     => $end_dt,
        @_
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor - Interact with LogicMonitor's API

=head1 VERSION

version 0.153170

=head1 SYNOPSIS

  use v5.16;
  use warnings;
  use Try::Tiny;
  use WebService::LogicMonitor;

  # find a hostgroup by name, iterate through its child groups
  # and check the status of a datasource instance

  my $lm = WebService::LogicMonitor->new(
      username => $ENV{LOGICMONITOR_USER},
      password => $ENV{LOGICMONITOR_PASS},
      company  => $ENV{LOGICMONITOR_COMPANY},
  );

  my $top_group_name = shift || die "What group?\n";
  my $datasource     = shift || 'Ping';

  sub recurse_group {
      my $group = shift;
      foreach my $entity (@{$group->children}) {
          if ($entity->is_group) {
              say 'GROUP: ' . $entity->name;
              recurse_group($entity);
          } elsif ($entity->is_host) {
              say '  HOST: ' . $entity->host_name;
              my $instances = try {
                  $entity->get_datasource_instances($datasource);
              } catch {
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

=head1 DESCRIPTION

LogicMonitor is a SaaS infrastructure monitoring provider. They provide an RPC
API which provides most of functionality of their web GUI (with the unfortunate
omission of managing DataSources).

They have recently started a REST API which covers a different set of functionality.

This module puts an OO wrapper around the RPC API in what is a hopefully a much
more convenient and user-friendly manner.

B<HOWEVER> the API provided by this module is not considered stable and will
almost certainly have some changes before version 1.0.

=head1 ATTRIBUTES

=head2 C<company>, C<username>, C<password>

The CUP authentication details for your LogicMonitor account. See
L<http://help.logicmonitor.com/developers-guide/authenticating-requests/>

=head1 METHODS

=head2 C<get_escalation_chains>

Returns an arrayref of all available escalation chains.

L<http://help.logicmonitor.com/developers-guide/manage-escalation-chains/#get1>

=head2 C<get_escalation_chain_by_name(Str $name)>

Convenience wrapper aroung L</get_escalation_chains> which only returns chains
where a C<name eq $name>.

=head2 C<get_accounts>

Retrieves a complete list of accounts as an arrayref.

L<http://help.logicmonitor.com/developers-guide/manage-user-accounts/#getAccounts>

=head2 C<get_account_by_email(Str $email)>

Convenience wrapper aroung L</get_accounts> which only returns accounts
matching $email.

=head2 C<get_account_by_username(Str $username)>

Convenience wrapper aroung L</get_accounts> which only returns accounts
matching C<$username>.

=head2 C<get_data>

=head2 C<get_alerts(...)>

Returns an arrayref of alerts or undef if none found.

See L<http://help.logicmonitor.com/developers-guide/manage-alerts/> for
what parameters are available to filter the alerts.

=head2 C<add_host>

Creates and returns a new host. Shortcut for L<WebService::LogicMonitor::Host>
C<new> and C<create>

=head2 C<delete_host(Str displayname)>

Deletes a host identified by its displayname. Convenience wrapper around
L<WebService::LogicMonitor/get_host> and L<WebService::LogicMonitor::Host/delete>.

=head2 C<get_host(Str displayname)>

Return a host.

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#get1>

=head2 C<get_hosts(Int hostgroupid)>

Return an array of hosts in the group specified by C<group_id>

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#get1>

In scalar context, will return an arrayref of hosts in the group.

In array context, will return the same arrayref plus a hashref of the group.

=head2 C<get_all_hosts>

Convenience wrapper around L</get_hosts> which returns all hosts. B<BEWARE> This will
probably take a while.

=head2 C<get_groups(Str|Regexp filter?)>

Returns an arrayref of all host groups.

L<http://help.logicmonitor.com/developers-guide/manage-host-group/#list>

Optionally takes a string or regexp as an argument. Only those hostgroups with names
matching the argument will be returned, or undef if there are none. If the arg is a string,
it must be an exact match with C<eq>.

=head2 C<get_sdts(Str key?, Int id?)>

Returns an array of SDT hashes. With no args, it will return all SDTs in the
account. See the LoMo docs for details on what keys are supported.

L<http://help.logicmonitor.com/developers-guide/schedule-down-time/get-sdt-data/>

=head2 C<set_sdt(Str entity, Int|Str id, start => DateTime|Str, end => DateTime|Str, comment => Str?)>

Sets SDT for an entity. Entity can be

  Host
  HostGroup
  HostDataSource
  DataSourceInstance
  HostDataSourceInstanceGroup
  Agent

The id for Host can be either an id number or hostname string.

To simplify calling this we take two keys, C<start> and C<end> which must
be either L<DateTime> objects or ISO8601 strings parseable by
L<DateTime::Format::ISO8601>.

L<http://help.logicmonitor.com/developers-guide/schedule-down-time/set-sdt-data/>

  $lomo->set_sdt(
      Host    => 'somehost',
      start   => '20151101T1000',
      end     => '20151101T1350',
      comment => 'Important maintenance',
  );

=head2 C<set_quick_sdt(Str entity, Int|Str id, $hours, ...)>

Wrapper around L</set_sdt> to quickly set SDT starting immediately. The lenght
of the SDT can be specfied as hours, minutes or any other unit supported by
L<https://metacpan.org/pod/DateTime#Adding-a-Duration-to-a-Datetime>, but only
one unit can be specified.

  $lomo->set_quick_sdt(Host => 'somehost', minutes => 30, comment => 'Reboot to annoy support');
  $lomo->set_quick_sdt(HostGroup => 456, hours => 6);

=head1 SEE ALSO

L<LogicMonitor|http://www.logicmonitor.com/>

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
