package YATG::Callback;
{
  $YATG::Callback::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use Readonly;
use SNMP;

use vars qw(@EXPORT_OK);
use base 'Exporter';
@EXPORT_OK = qw(snmp_callback);

Readonly my $ifignore => qr/stack|null|span|unrouted|eobc|netflow|loopback|plane/i;

sub snmp_callback {
    my ($host, $error) = @_;
    my $cache   = YATG::SharedStorage->cache()   || {};
    my $results = YATG::SharedStorage->results() || {};
    my $stash   = {};

    if ($error) {
        warn "$host failed with this error: $error\n";
        return;
    }

    # rename data result keys so we can use them with aliases
    my $data = $host->data;
    foreach my $oid (keys %$data) {
        next if $oid =~ m/^\./;
        $data->{".$oid"} = delete $data->{$oid};
    }

    my $descr = $cache->{oid_for}->{ifDescr};
    my $admin = $cache->{oid_for}->{ifAdminStatus};
    if ($cache->{$host}->{build_ifindex}) {
        foreach my $iid (keys %{$data->{$descr}}) {
            next if $data->{$descr}->{$iid} =~ $ifignore;
            next if $data->{$admin}->{$iid} != 1;

            $stash->{$iid}->{is_interesting} = 1;
        }
    }

    foreach my $oid (keys %$data) {
        my $leaf  = $cache->{leaf_for}->{$oid};
        my $store_list = $cache->{oids}->{$leaf}->{store_list};
        next if !defined $store_list or scalar @$store_list == 0;

        # only a hint, as some INTEGERs are not enumerated types
        my $enum = SNMP::getType($leaf) eq 'INTEGER' ? 1 : 0;
        my $enum_val = undef;

        if ($cache->{oids}->{$leaf}->{indexer} eq 'iid') {
            foreach my $iid (keys %{$data->{$oid}}) {
                next unless $stash->{$iid}->{is_interesting};
                my $enum_val = SNMP::mapEnum($leaf, $data->{$oid}->{$iid})
                    if $enum;

                foreach my $store (@$store_list) {
                    $results->{$store}->{$host}->{$leaf}
                        ->{$data->{$descr}->{$iid}} = ($enum and defined $enum_val)
                            ? $enum_val : $data->{$oid}->{$iid};
                } # store
            }
        }
        else {
            foreach my $id (keys %{$data->{$oid}}) {
                my $enum_val = SNMP::mapEnum($leaf, $data->{$oid}->{$id})
                    if $enum;

                foreach my $store (@$store_list) {
                    $results->{$store}->{$host}->{$leaf}->{$id}
                        = ($enum and defined $enum_val)
                            ? $enum_val : $data->{$oid}->{$id};
                } # store
            }
        }
    }
}

1;
