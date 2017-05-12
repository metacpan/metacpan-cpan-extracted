package Example;

use strict;
use warnings;

use Net::SNMP qw(:ALL);
use Carp;

our $VERSION = 1.01;

# Blocking SNMPv1 get-request for sysUpTime
sub example1 {
    my $OID_sysUpTime = '1.3.6.1.2.1.1.3.0';

    my ($session, $error) = Net::SNMP->session(
        -hostname  => shift || 'localhost',
        -community => shift || 'public',
    );

    if (!defined $session) {
        croak "ERROR: $error";
    }

    my $result = $session->get_request(-varbindlist => [$OID_sysUpTime],);

    if (!defined $result) {
        my $rerror = $session->error();
        $session->close();
        croak 'ERROR: ' . $rerror;
    }

    my ($host, $return) = ($session->hostname(), $result->{$OID_sysUpTime});

    $session->close();
    return $host, $return;
}

#  Blocking SNMPv3 set-request of sysContact
sub example2 {
    my $OID_sysContact = '1.3.6.1.2.1.1.4.0';

    my ($session, $error) = Net::SNMP->session(
        -hostname     => 'myv3host.example.com',
        -version      => 'snmpv3',
        -username     => 'myv3Username',
        -authprotocol => 'sha1',
        -authkey      => '0x6695febc9288e36282235fc7151f128497b38f3f',
        -privprotocol => 'des',
        -privkey      => '0x6695febc9288e36282235fc7151f1284',
    );

    if (!defined $session) {
        croak 'ERROR: ' . $error;
    }

    my $result = $session->set_request(-varbindlist => [ $OID_sysContact, OCTET_STRING, 'Help Desk x911' ],);

    if (!defined $result) {
        my $rerror = $session->error();
        $session->close();
        croak 'ERROR: ' . $rerror;
    }

    my ($host, $return) = ($session->hostname(), $result->{$OID_sysContact});

    $session->close();

    return $host, $return;
}

# Non-blocking SNMPv2c get-bulk-request for ifTable
sub example3 {
    my $OID_ifTable       = '1.3.6.1.2.1.2.2';
    my $OID_ifPhysAddress = '1.3.6.1.2.1.2.2.1.6';

    my ($session, $error) = Net::SNMP->session(
        -hostname  => shift || 'localhost',
        -community => shift || 'public',
        -nonblocking => 1,
        -translate   => [ -octetstring => 0 ],
        -version     => 'snmpv2c',
    );

    if (!defined $session) {
        croak 'ERROR: ' . $error;
    }

    my %table;    # Hash to store the results

    my $result = $session->get_bulk_request(
        -varbindlist    => [$OID_ifTable],
        -callback       => [ \&table_callback, \%table ],
        -maxrepetitions => 10,
    );

    if (!defined $result) {
        my $rerror = $session->error();
        $session->close();
        croak 'ERROR: ' . $rerror;
    }

    # Now initiate the SNMP message exchange.

    $session->snmp_dispatcher();

    $session->close();

    return \%table;
}

sub table_callback {
    my ($session, $table) = @_;

    my $list = $session->var_bind_list();

    if (!defined $list) {
        printf "ERROR: %s\n", $session->error();
        return;
    }

    # Loop through each of the OIDs in the response and assign
    # the key/value pairs to the reference that was passed with
    # the callback.  Make sure that we are still in the table
    # before assigning the key/values.

    my @names = $session->var_bind_names();
    my $next  = undef;

    my $OID_ifTable = '1.3.6.1.2.1.2.2';
    while (@names) {
        $next = shift @names;
        if (!oid_base_match($OID_ifTable, $next)) {
            return;    # Table is done.
        }
        $table->{$next} = $list->{$next};
    }

    # Table is not done, send another request, starting at the last
    # OBJECT IDENTIFIER in the response.  No need to include the
    # calback argument, the same callback that was specified for the
    # original request will be used.

    my $result = $session->get_bulk_request(
        -varbindlist    => [$next],
        -maxrepetitions => 10,
    );

    if (!defined $result) {
        printf "ERROR: %s.\n", $session->error();
    }

    return;
}

# Non-blocking SNMPv1 get-request and set-request on multiple hosts
sub example4 {
    my $OID_sysUpTime   = '1.3.6.1.2.1.1.3.0';
    my $OID_sysContact  = '1.3.6.1.2.1.1.4.0';
    my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';

    # Hash of hosts and location data.

    my %host_data = (
        '10.1.1.2'  => 'Building 1, Second Floor',
        '10.2.1.1'  => 'Building 2, First Floor',
        'localhost' => 'Right here!',
    );

    # Create a session for each host and queue a get-request for sysUpTime.

    for my $host (keys %host_data) {

        my ($session, $error) = Net::SNMP->session(
            -hostname    => $host,
            -community   => 'private',
            -nonblocking => 1,
        );

        if (!defined $session) {
            carp "ERROR: Failed to create session for host '$host': $error.\n";
            next;
        }

        my $result = $session->get_request(
            -varbindlist => [$OID_sysUpTime],
            -callback    => [ \&get_callback, $host_data{$host} ],
        );

        if (!defined $result) {
            carp q{ERROR: Failed to queue get request for host '} . $session->hostname() . q{': } . $session->error();
        }

    }

    # Now initiate the SNMP message exchange.

    snmp_dispatcher();

    return 1;
}

sub get_callback {
    my ($session, $location) = @_;

    my $result = $session->var_bind_list();

    if (!defined $result) {
        printf "ERROR: Get request failed for host '%s': %s.\n", $session->hostname(), $session->error();
        return;
    }

    my $OID_sysUpTime   = '1.3.6.1.2.1.1.3.0';
    my $OID_sysContact  = '1.3.6.1.2.1.1.4.0';
    my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';
    printf "The sysUpTime for host '%s' is %s.\n", $session->hostname(), $result->{$OID_sysUpTime};

    # Now set the sysContact and sysLocation for the host.

    $result = $session->set_request(
        -varbindlist => [ $OID_sysContact, OCTET_STRING, 'Help Desk x911', $OID_sysLocation, OCTET_STRING, $location, ],
        -callback    => \&set_callback,
    );

    if (!defined $result) {
        printf "ERROR: Failed to queue set request for host '%s': %s.\n", $session->hostname(), $session->error();
    }

    return;
}

sub set_callback {
    my ($session) = @_;

    my $OID_sysContact  = '1.3.6.1.2.1.1.4.0';
    my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';
    my $result          = $session->var_bind_list();

    if (defined $result) {
        printf "The sysContact for host '%s' was set to '%s'.\n",  $session->hostname(), $result->{$OID_sysContact};
        printf "The sysLocation for host '%s' was set to '%s'.\n", $session->hostname(), $result->{$OID_sysLocation};
    } else {
        printf "ERROR: Set request failed for host '%s': %s.\n", $session->hostname(), $session->error();
    }

    return;
}

1;
