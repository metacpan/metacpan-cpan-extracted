package YATG::Store::NSCA;
{
  $YATG::Store::NSCA::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use YATG::SharedStorage;
YATG::SharedStorage->factory(qw( ifOperStatus ifInErrors ifInDiscards ));

# initialize cache of previous run's data
YATG::SharedStorage->ifOperStatus({});
YATG::SharedStorage->ifInErrors({});
YATG::SharedStorage->ifInDiscards({});

sub echo { main::to_log(shift) if $ENV{YATG_DEBUG} }

sub store {
    my ($config, $stamp, $results) = @_;

    my $ignore_ports = $config->{nsca}->{ignore_ports};
    my $ignore_descr = $config->{nsca}->{ignore_descr};

    my $ignore_status_descr  = $config->{nsca}->{ignore_status_descr};
    my $ignore_error_descr   = $config->{nsca}->{ignore_error_descr};
    my $ignore_discard_descr = $config->{nsca}->{ignore_discard_descr};

    my $send_nsca_cmd  = $config->{nsca}->{send_nsca_cmd};
    my $send_nsca_cfg  = $config->{nsca}->{config_file};
    my $service_prefix = $config->{nsca}->{service_prefix};

    my $ifOperStatusCache = YATG::SharedStorage->ifOperStatus();
    my $ifInErrorsCache   = YATG::SharedStorage->ifInErrors();
    my $ifInDiscardsCache = YATG::SharedStorage->ifInDiscards();

    my $threshold = $config->{nsca}->{threshold}
      || int($config->{yatg}->{interval} / 60);

    my $cache = YATG::SharedStorage->cache();
    my $nsca_server = $config->{nsca}->{nsca_server}
        or die "Must specify an nsca server in configuration.\n";
    my $nsca_port = $config->{nsca}->{nsca_port};

    # results look like this:
    #   $results->{device}->{leaf}->{port} = {value}
    # build instead
    #   $status->{device}->{port}->{leaf} = {value}

    my $status = {};
    foreach my $device (keys %$results) {
        foreach my $leaf (keys %{$results->{$device}}) {
            foreach my $port (keys %{$results->{$device}->{$leaf}}) {
                $status->{$device}->{$port}->{$leaf}
                    = $results->{$device}->{$leaf}->{$port};
            } # port
        } # leaf
    } # device

    # get handle in outer scope
    open my $oldout, '>&', \*STDOUT or die "Can't dup STDOUT: $!";

    # back up STDOUT then redirect it to quieten send_nsca command
    unless ($ENV{YATG_DEBUG} || $config->{yatg}->{debug}) {
        open STDOUT, '>', '/dev/null'   or die "Can't redirect STDOUT: $!";
    }

    # open connection to send_nsca
    open(my $send_nsca, '|-', (split /\s+/, $send_nsca_cmd),
                              '-H', $nsca_server, '-p', $nsca_port,
                              '-c', $send_nsca_cfg, '-d', '!', '-to', 1)
        or die "can't fork send_nsca: $!";

    # build and send report for each host
    foreach my $device (keys %$status) {
        my $status_report   = q{}; # combine the error messages to fit in nagios report
        my $errors_report   = q{}; # combine the error messages to fit in nagios report
        my $discards_report = q{}; # combine the error messages to fit in nagios report

        my $tot_oper = 0;
        my $tot_down = 0;
        my $tot_err  = 0;
        my $tot_with_err  = 0;
        my $tot_dis  = 0;
        my $tot_with_dis  = 0;

        my @ports_list = exists $cache->{'interfaces_for'}->{$device}
          ? keys %{ $cache->{'interfaces_for'}->{$device} }
          : keys %{ $status->{$device} };

        #use Data::Printer;
        #p $status->{$device};

        foreach my $port (@ports_list) {
            next if $port =~ m/$ignore_ports/;

            my $ifOperStatus = $status->{$device}->{$port}->{ifOperStatus};
            my $ifInErrors   = $status->{$device}->{$port}->{ifInErrors};
            my $ifInDiscards = $status->{$device}->{$port}->{ifInDiscards};

            my $ifAlias = $status->{$device}->{$port}->{ifAlias} || '';
            next if length $ifAlias and $ifAlias =~ m/$ignore_descr/;

            my $skip_oper = (length $ifAlias and $ignore_status_descr
              and $ifAlias =~ m/$ignore_status_descr/) ? 1 : 0;
            my $skip_err  = (length $ifAlias and $ignore_error_descr
              and $ifAlias =~ m/$ignore_error_descr/) ? 1 : 0;
            my $skip_disc = (length $ifAlias and $ignore_discard_descr
              and $ifAlias =~ m/$ignore_discard_descr/) ? 1 : 0;

            if (exists $status->{$device}->{$port}->{ifOperStatus}) {
                if (not $skip_oper and $ifOperStatus !~ m/^(?:up|dormant)/) {
                    $status_report ||= 'NOT OK - DOWN: ';
                    $status_report .= "$port($ifAlias) ";
                    ++$tot_down;
                }

                # update cache
                $ifOperStatusCache->{$device}->{$port} = $ifOperStatus;
                ++$tot_oper;

                if ($ifOperStatus !~ m/^(?:up|dormant)/) {
                    # can skip rest of this port's checks and reports
                    $ifInErrorsCache->{$device}->{$port} = $ifInErrors
                      if exists $status->{$device}->{$port}->{ifInErrors};
                    $ifInDiscardsCache->{$device}->{$port} = $ifInDiscards
                      if exists $status->{$device}->{$port}->{ifInDiscards};
                    next;
                }
            }

            if (exists $status->{$device}->{$port}->{ifInErrors}) {
                # compare cache
                if (not $skip_err
                    and exists $ifInErrorsCache->{$device}->{$port}) {

                    my $diff = ($ifInErrors - $ifInErrorsCache->{$device}->{$port});
                    if ($diff > $threshold) {
                        $errors_report ||= 'NOT OK - Errors: ';
                        $errors_report .= "$port(+$diff)($ifAlias) ";
                        ++$tot_with_err;
                    }
                }

                # update cache
                $ifInErrorsCache->{$device}->{$port} = $ifInErrors;
                ++$tot_err;
            }

            if (exists $status->{$device}->{$port}->{ifInDiscards}) {
                # compare cache
                if (not $skip_disc
                    and exists $ifInDiscardsCache->{$device}->{$port}) {

                    my $diff = ($ifInDiscards - $ifInDiscardsCache->{$device}->{$port});
                    if ($diff > $threshold) {
                        $discards_report ||= 'NOT OK - Discards: ';
                        $discards_report .= "$port(+$diff)($ifAlias) ";
                        ++$tot_with_dis;
                    }
                }

                # update cache
                $ifInDiscardsCache->{$device}->{$port} = $ifInDiscards;
                ++$tot_dis;
            }
        } # port

        $status_report   = "NOT OK - $tot_down (of $tot_oper polled) interfaces are DOWN."
          if $tot_down > 10;
        $errors_report   = "NOT OK - $tot_with_err (of $tot_err UP) interfaces have errors."
          if $tot_with_err > 10;
        $discards_report = "NOT OK - $tot_with_dis (of $tot_dis UP) interfaces have discards."
          if $tot_with_dis > 10;

        my $host = exists $cache->{host_for} ? $cache->{host_for}->{$device}
                                             : $device;

        # $ECHO "$SERVER;$SERVICE;$RESULT;$OUTPUT" | $CMD -H $DEST_HOST -c $CFG -d ";"

        if (exists $results->{$device}->{ifOperStatus}) {
            if (length $status_report) {
                my $output = "$host!$service_prefix Status!2!$status_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Status!0!OK: $tot_oper interfaces are UP and running.\n";
                echo $output;
                print $send_nsca $output;
            }
        }

        if (exists $results->{$device}->{ifInErrors}) {
            if (length $errors_report) {
                my $output = "$host!$service_prefix Errors!2!$errors_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Errors!0!OK: No errors on $tot_err UP interfaces.\n";
                echo $output;
                print $send_nsca $output;
            }
        }

        if (exists $results->{$device}->{ifInDiscards}) {
            if (length $discards_report) {
                my $output = "$host!$service_prefix Discards!2!$discards_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Discards!0!OK: No discards on $tot_dis UP interfaces.\n";
                echo $output;
                print $send_nsca $output;
            }
        }
    } # host

    # close connection to send_nsca (will chirp)
    close $send_nsca or die "can't close send_nsca: $!";

    # restore STDOUT
    open STDOUT, '>&', $oldout or die "Can't dup \$oldout: $!";

    return 1;
}

1;

# ABSTRACT: Back-end module to send polled data to a Nagios service


__END__
=pod

=head1 NAME

YATG::Store::NSCA - Back-end module to send polled data to a Nagios service

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

This module checks interface status, errors and discard counts and sends
a result to Nagios C<nsca> process for each.

Only one check result per device is submitted (i.e. I<not> one result per
port). If there are multiple ports in an alarm state on the same device, then
they will all be mentioned in the single service check report.

When all enabled ports are connected, an OK result is returned.

=head1 CONFIGURATION

At a minimum, you must provide details of the location of your Nagios NSCA
server, in the main configuration file:

 nsca:
     nsca_server: '192.0.2.1'

In your YATG configuration file, you must also include this store module on
the OIDs required to generate a check result:

 oids:
     "ifAlias":        [ifindex, nsca]
     "ifOperStatus":   [ifindex, nsca]
     "ifInErrors":     [ifindex, nsca]
     "ifInDiscards":   [ifindex, nsca]

Note that each of the C<ifOperStatus>, C<ifInErrors> and C<ifInDiscards> is
optional, and that you should provide at least one. The C<ifAlias> is also
optional but helps in the status report.

=head2 Optional Configuration

You can also supply the following settings in the main configuration file to
override builtin defaults, like so:

 yatg:
     dbi_host_query: 'SELECT ip, host AS name from hosts'
     dbi_community_query: 'SELECT ip, snmp_community FROM hosts'
     dbi_interfaces_query: 'SELECT name FROM hostinterfaces WHERE ip = ?'
 nsca:
     nsca_port: '5667'
     send_nsca_cmd: '/usr/bin/send_nsca'
     config_file:   '/etc/send_nsca.cfg'
     ignore_ports:  '^(?:Vlan|Po)\d+$'
     ignore_descr:  '(?:SPAN)'
     ignore_oper_descr:    '(?:TEST)'
     ignore_error_descr:   '(?:NOERR)'
     ignore_discard_descr: '(?:NODIS)'
     service_prefix:  'Interfaces'
     threshold:  '5'

=over 4

=item C<dbi_host_query>

You can choose to submit results by host name instead of IP. To allow this,
you need a configuration entry with an SQL query. The query must return two
columns, named I<ip> and I<name>. For example:

 yatg:
     dbi_host_query: 'SELECT ip, host AS name from hosts'

=item C<dbi_community_query>

For performance you can retrieve community strings from a database instead
of trying a list in turn for each device (which is very slow indeed). Pass
an SQL statement which returns the IP and community string for each device.
If used, this option causes YATG to ignore the C<communities> configuration.

 yatg:
     dbi_community_query: 'SELECT ip, snmp_community FROM hosts'

=item C<dbi_interfaces_query>

This option allows filtering of submitted results according to a list of
Interface names on the device. The SQL in this case needs one "bind var" for
the device IP, and must return a single list of names (again, used in
C<DBI::selectcol_arrayref>):

 yatg:
     dbi_interfaces_query: 'SELECT name FROM hostinterfaces WHERE ip = ?'

With this option you have an explicit list of interface names. You can also
use the C<ignore_*> options (see below) to filter interfaces based on a
regular expression.

=item C<send_nsca_cmd>

The location of the C<send_nsca> command on your system. YATG will default to
C</usr/bin/send_nsca> and if you supply a value it must be a fully qualified
path.

=item C<nsca_port>

The port where the NSCA daemon is listening, and the C<send_nsca> command
should connect and submit results.

=item C<config_file>

The location of the configuration file for the C<send_nsca> program. This
defaults to C</etc/send_nsca.cfg>.

=item C<ignore_ports>

Device port names (OID C<ifDescr>) to skip when submitting results. This
defaults to anything like a Vlan interface, or Cisco PortChannel. Supply the
content of a Perl regular expression, as in the example above.

=item C<ignore_descr>

Device port description fields matching this value cause the port to be
skipped when submitting results. This defaults to anything containing the word
"SPAN". Supply the content of a Perl regular expression, as in the example
above.

=item C<ignore_oper_descr>, C<ignore_error_descr>, C<ignore_discard_descr>

This setting has the same effect as C<ignore_descr> but applies only to the
port status, port error count, and port discard count checks, respectively.
There is no default setting for these options.

=item C<service_prefix>

Prefix of he Nagios Service Check name to use when submitting results. To this
is added the name of the data check such as "Status" or "Errors".  This must
match the configured name on your Nagios server, and defaults to "Interfaces".

=item C<threshold>

Quantity of Errors or Discards which have to appear on an Interface in a
reporting period before an alert is generated. The default is the check
interval divided by 60 (that is, for checks every five minutes, the threshold
is five).

=back

=head1 SEE ALSO

=over 4

=item Nagios NSCA at L<http://docs.icinga.org/latest/en/nsca.html>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

