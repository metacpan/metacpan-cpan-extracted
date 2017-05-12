package YATG::Config;
{
  $YATG::Config::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use Module::MultiConf 0.0301;

__PACKAGE__->Validate({
    yatg => {
        oids         => { type => HASHREF },
        dbi_connect  => { type => ARRAYREF },
        dbi_ip_query => { type => SCALAR, default =>
'SELECT ip FROM device WHERE extract(epoch from last_macsuck) > (extract(epoch from now()) - 7200)' },
        dbi_host_query => { type => SCALAR, optional => 1 },
        dbi_interfaces_query => { type => SCALAR, optional => 1 },
        interval     => { type => SCALAR, default => 300 },
        timeout      => { type => SCALAR, default => 280 },
        max_pollers  => { type => SCALAR, default => 20  },
        debug        => { type => SCALAR, default => 0   },
        communities  => { type => SCALAR | ARRAYREF,
                                          default => 'public' },
        mibdirs      => { type => ARRAYREF, default => [qw(
            /usr/share/netdisco/mibs/cisco
            /usr/share/netdisco/mibs/rfc
            /usr/share/netdisco/mibs/net-snmp
        )] },
        disk_root    => { type => SCALAR, default => '/var/lib/yatg' },
        newhosts_watch => { type => SCALAR, optional => 1 },
    },
    cache_memcached => {
        servers   => { type => ARRAYREF, optional => 1 },
        namespace => { type => SCALAR, default => 'yatg:' },
    },
    rpc_serialized_client_inet => {
        data_serializer => { type => HASHREF,
                             default => {serializer => 'YAML::Syck'} },
        io_socket_inet  => { type => HASHREF, optional => 1 },
    },
    log_dispatch_syslog => {
        name      => { type => SCALAR, default => 'yatg' },
        ident     => { type => SCALAR, default => 'yatg' },
        min_level => { type => SCALAR, default => 'info' },
        facility  => { type => SCALAR, default => 'local1' },
        callbacks => { type => CODEREF | ARRAYREF,
                            default => sub { return "$_[1]\n" } },
    },
    nsca => {
        nsca_server    => { type => SCALAR, optional => 1 },
        nsca_port      => { type => SCALAR, default => '5667' },
        send_nsca_cmd  => { type => SCALAR, default => '/usr/bin/send_nsca' },
        config_file    => { type => SCALAR, default => '/etc/send_nsca.cfg' },
        ignore_ports   => { type => SCALAR, default => '^(?:Vlan|Po)\d+$' },
        ignore_descr   => { type => SCALAR, default => '(?:SPAN)' },
        ignore_oper_descr    => { type => SCALAR, optional => 1 },
        ignore_error_descr   => { type => SCALAR, optional => 1 },
        ignore_discard_descr => { type => SCALAR, optional => 1 },
        service_prefix => { type => SCALAR, default => 'Interfaces' },
        threshold => { type => SCALAR, optional => 1 },
    },
});

1;

# ABSTRACT: Configuration management for YATG


__END__
=pod

=head1 NAME

YATG::Config - Configuration management for YATG

=head1 VERSION

version 5.140510

=head1 REQUIRED CONFIGURATION

C<yatg_updater> expects one command line argument, which is its main
configuration file. This must be in a format recognizable to L<Config::Any>,
and you must use a file name suffix to give that module a hint.

There is a fairly complete example of this configuration file in the
C<examples/> folder of this distribution - look for the C<yatg.yml> file. The
file must parse out to an anonymous hash of hashes, as in the example.

Let's first consider the C<yatg> key/value, which is the main configuration
area.

=head2 oids

This is a hash, with keys being the Leaf Name of an SNMP OID. This tells
C<yatg_updater> the list of OIDs which you would like gathering from each
network device. The value for each leaf name key is a list of magic words
which tell C<yatg_updater> whether to get the OID, and what to do with the
results. Some of the magic words are mutually exclusive.

 # example key and "magic words" list value
 yatg:
     oids:
         ifOperStatus: [disk, ifindex]

=head3 Storage

These are the storage methods for the results, and an OID without one of these
magic words will be ignored. Multiple storage methods can be given for any OID.

=over 4

=item C<stdout>

This means to use the L<Data::Printer> to print results.  It's good for
testing.

See L<YATG::Store::STDOUT>.

=item C<disk>

Disk storage means to create a file for each OID of each port on each device.
It is very fast and efficient by design, and most useful for long-term
historical data such as port traffic counters.

See L<YATG::Store::Disk>.

=item C<memcached>

If you don't need data history, then this module is a better alternative than
disk-based storage, because of its speed. A memcached server is required of
course.

See L<YATG::Store::Memcached>.

=item C<rpc>

This is merely an extension to the Disk storage module which allows
C<yatg_updater> to use disk on another machine. You can think of it as an
RPC-based alternative to network mounting a filesystem. On the remote host,
the Disk module is then used for storage.

See L<YATG::Store::RPC>.

=item C<nsca>

If you wish to submit data to Nagios as a passive service check result, then
this method can be configured to contact an NSCA daemon on your Nagios server.

See L<YATG::Store::NSCA>.

=back

=head3 Interface Indexed OIDs

Although C<yatg_updater> will happily poll single value or plain indexed OIDs,
you can give it a hint that there is an interface-indexed OID in use.

In that case, C<yatg_updater> will make sure that C<IfDescr> and
C<IfAdminStatus> are retrieved from the device, and results will be keyed by
human-friendly names (e.g. C<FastEthernet2/1>) rather than SNMP interface
indexes (e.g. C<10101>).

Furthermore, only results for "interesting" interfaces will be stored. This is
defined as interfaces which are administratively configured to the "up" state,
and whose name does not match an exclusion list (various private
sub-interfaces, which are uninteresting). This measure will save you time when
storing results to disk as you only save what is interesting. If you store
results for a port, then shut it down and some time later start it up again,
the results file will be padded out for the period of shut-down time and
appended with the new results.

Being indexed by interface is something C<yatg_updater> cannot work out for
itself for an OID, so provide the C<ifindex> magic word to enable this
feature.

=head3 IP address filtering

We have not yet covered how C<yatg_updater> obtains its list of devices to
poll, but for now all you need to know is that by default all listed leaf
names will be polled on all devices.

You can however provide magic words to override this behaviour and reduce the
device space to be polled for a leaf name. Each of these magic words may
appear more than once:

=over 4

=item C<192.2.1.10> or C<192.1.1.0/24>

Any IP address or IP subnet will be taken as a restriction placed upon the
default list of device IPs, for this OID only.

Not providing an explicit IP address or IP subnet means the OID will be polled
on all devices in the default list.

=item C<!192.2.1.10> or C<!192.1.1.0/24>

Using an exclamation mark at the head of the IP address introduces an
exclusion filter upon the cached list of IP addresses.

This prevents the OID from being checked on the given devices, even if the
device IP is also given in a magic word, as above.

=back

In case it is not clear, an IP address and an IP subnet are no different - a
C</32> subnet mask is assumed in the case of an IP address.

=head2 communities

Provide a list of SNMP community strings to the system using this parameter.
For each device, at startup, C<yatg_updater> will work out which community to
use and cache that for subsequent SNMP polling. For example:

 yatg:
     communities: [public, anotherone]

The default value for this is C<[ public ]>.

=head2 dbi_connect and the list of devices

At start-up, C<yatg_updater> needs to be given a list of device IPs which it
should poll with SNMP. C<yatg_updater> will make a connection to a database
and gather IPs.

By default the SQL query is set for use with NetDisco, so if you use that
system you only need alter the DBI connection parameters (password, etc) in
the C<dbi_connect> value in the example configuration file.

If you want to use a different SQL query, add a new key and value to the
configuration:

 yatg:
     dbi_ip_query: 'SELECT ip FROM device;'

The query must return a single list of IPs (suitable for L<DBI>'s
C<selectcol_arrayref>). If you don't have a back-end database with such
information, then install SQLite and quickly set one up (see L<YATG::Tutorial>
for help). It's good practice for asset management, if nothing else.

=head2 mibdirs

If you use NetDisco, and have the MIB files from that distribution installed
in C</usr/share/netdisco/mibs/...> then you can probably ignore this as the
default will work.

Otherwise, you must provide this application with all the MIBs required to
translate leaf names to OIDs and get data types for polled values. This key
takes a list of directories on your system which contain MIB files. They will
all be loaded when C<yatg_updater> starts, so only specify what you need
otherwise that will take a long time.

Here is an example in YAML:

 yatg:
     mibdirs:
         ['/usr/share/netdisco/mibs/cisco',
          '/usr/share/netdisco/mibs/rfc',
          '/usr/share/netdisco/mibs/net-snmp']

=head1 OPTIONAL CONFIGURATION

There are some additional, optional keys for the C<yatg> section:

=over 4

=item C<interval>

C<yatg_updater> polls all devices at a given interval. Provide a number of
settings to this key if you want to override the default of 300 (5 minutes).
An alternative is the C<YATG_INTERVAL> environment setting.

=item C<timeout>

If the poller does not return data from all devices within C<timeout> seconds,
then the application will die. The default is 280. You should always have a
little head-room between the C<timeout> and C<interval>.

=item C<max_pollers>

This system uses C<SNMP::Effective> for the SNMP polling, which is a fast,
lightweight wrapper to the C<SNMP> perl libraries. C<SNMP::Effective> polls
asynchronously and you can set the maximum number of polls which are happening
at once using this key. The default is 20 which is reasonably for any modern
computer.

=item C<newhosts_watch>

As YATG is a long-running process, you might occasionally want to update its
list of hosts to monitor. Of course you can send a C<SIGHUP> and have YATG
reload entirely, but this can be slow because of the re-checking of SNMP
communities, and also requires an external process to send the signal.

If the YATG config has not changed, but you wish to update the list of
monitored hosts, then set C<newhosts_watch> to the name of a file. The
modification time of the file is watched and if it updates then YATG retrieves
a new set of hosts (and host names and interface filters, if configured), on
the next polling run.

=item C<debug>

If this key has a true value, C<yatg_updater> will print out various messages
on standard output, instead of using a log file. It's handy for testing, and
defaults to false of course. An alternative is the C<YATG_DEBUG> environment
setting.

=back

=head1 LOGGING CONFIGURATION

This module uses C<Log::Dispatch::Syslog> for logging, and by default will log
timing data to your system's syslog service. The following parameters can be
overridden in a section at the same level as C<oids>, but called
C<log_dispatch_syslog>:

=over 4

=item C<name> and C<ident>

These are the tokens used to identify the process to syslog, and both default
to C<yatg>.

=item C<min_level>

By default the logging level will be C<info> so override this to change that.

=item C<facility>

By default the syslog facility will be C<local1> so override this to change
that.

=back

Here is an example of what you might do:

 log_dispatch_syslog:
     name:       'my_app'
     ident:      'my_app'
     min_level:  'warning'
     facility:   'local4'

=head1 SEE ALSO

=over 4

=item L<http://www.netdisco.org/>

=item L<http://www.sqlite.org/>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

