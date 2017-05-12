package YATG::Store::Memcached;
{
  $YATG::Store::Memcached::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use Cache::Memcached;

sub store {
    my ($config, undef, $results) = @_;

    die "Must specify list of cache server(s)\n"
        unless ref $config->{cache_memcached}->{servers} eq 'ARRAY'
               and scalar @{$config->{cache_memcached}->{servers}} > 0;

    # get connection to Memcached server
    my $m = eval {
        Cache::Memcached->new( $config->{cache_memcached} )
    } or die "yatg: FATAL: memcached initialization failed: $@\n";

    # results look like this:
    #   $results->{host}->{leaf}->{port} = {value}
    my $TTL = $config->{yatg}->{interval} || 300;
    $TTL += (int (20 / 100 * $TTL)); # 20 p/c breathing space for splayed storage
    # $TTL = 2 * $TTL; # see if this helps nagios

    eval { $m->set('yatg_devices', [keys %$results], $TTL) }
        or warn "yatg: failed to store 'yatg_devices' to memcached\n";

    # send results
    foreach my $device (keys %$results) {
        foreach my $leaf (keys %{$results->{$device}}) {
            eval { $m->set("ports_for:$device",
                [keys %{$results->{$device}->{$leaf}}], $TTL) }
                or warn "yatg: failed to store 'ports_for:$device' to memcached\n";

            foreach my $port (keys %{$results->{$device}->{$leaf}}) {

                (my $key = join ':', $device, $leaf, $port) =~ s/\s/_/g;
                my $val = $results->{$device}->{$leaf}->{$port} || 0;

                if (grep m/^diff$/, @{$config->{yatg}->{oids}->{$leaf}}) {
                    my $oval = $m->get($key) || '0:0';
                    my (undef, $old) = split ':', $oval;
                    $old ||= $val;
                    $val = "$old:$val";
                }

                eval { $m->set($key, $val, $TTL) }
                    or warn "yatg: failed to store '$key' to memcached\n";
            } # port
        } # leaf
    } # device

    return 1;
}

1;

# ABSTRACT: Back-end module to store polled data to a Memcached


__END__
=pod

=head1 NAME

YATG::Store::Memcached - Back-end module to store polled data to a Memcached

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

This module implements part of a callback handler used to store SNMP data into
a memcached service. It will be faster than storing to disk, and so is
recommended if you do not require historical data.

The module will die if it cannot connect to your memcached server, so see
below for the configuration guidelines. Note that all example keys here use
the namespace prefix of C<yatg:> although this is configurable.

One data structure is passed in, which represents a set of results for a set of
polled OIDs on some devices. It looks a bit like this:

 $results->{$device}->{$leaf}->{$port} = {value}

In your memcached server, a few well-known keys store lists of polled devices
and so on, to help you bootstrap to find stored results.

The key C<yatg:yatg_devices> will contain an array reference containing all
device IPs provided in the results data.

Further, each key of the form C<yatg:ports_for:$device> will contain an array
reference containing all ports polled on that device. The port name is not
munged in any way. The "port" entity might in fact just be an index value, or
C<1> if this OID is not Interface Indexed.

Finally, the result of a poll is stored in memcached with a key of the
following format:

 yatg:$device:$leaf:$port

Note that the C<$leaf> is the SNMP leaf name and not the OID. That key will be
munged to remove whitespace, as that is not permitted in memcached keys.

All of the above values are stored with a TTL of the polling interval as
gathered from the main C<yatg_updater> configuration.

With all this information it is possible to write a script to find all the
data stored in the memcache using the two lookup tables and then retrieving
the desired keys. There is an example of this in the C<examples/> folder of
this distribution, called C<check_interfaces>. It is a Nagios2 check script.

=head1 REQUIREMENTS

Install the following additonal module to use this plugin:

=over 4

=item *

L<Cache::Memcached>

=back

=head1 CONFIGURATION

In the main C<yatg_updater> configuration, you must provide details of the
location of your memcached server. Follow the example (C<yatg.yml>) file in
this distribution. Remember you can override the namespace used from the
default of C<yatg:>, like so:

 cache_memcached:
     namespace: 'my_space:'

=head1 SEE ALSO

=over 4

=item L<Cache::Memcached>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

