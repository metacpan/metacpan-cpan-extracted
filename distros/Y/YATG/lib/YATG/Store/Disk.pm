package YATG::Store::Disk;
{
  $YATG::Store::Disk::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use Time::Local;
use Tie::File::FixedRecLen::Store;

sub store {
    my ($config, $stamp, $results) = @_;
    my $root = $config->{yatg}->{disk_root};

    # results look like this:
    #   $results->{host}->{leaf}->{port} = {value}

    foreach my $device (keys %$results) {
        eval { mkdir "$root/$device" };

        foreach my $leaf (keys %{$results->{$device}}) {
            my %data = %{$results->{$device}->{$leaf}};

            foreach my $port (keys %data) {
                (my $mport = $port) =~ s/[^A-Za-z0-9]/./g;

                my @files = grep {m/\d{4}-\d\d-\d\d_\d\d-\d\d-\d\dZ?,\d+$/}
                                 glob("$root/$device/$leaf/$mport/*");
    
                my (@store, $filename, $offset);
    
                if (scalar @files == 0) {
                    eval { mkdir "$root/$device/$leaf" };
                    eval { mkdir "$root/$device/$leaf/$mport" };
    
                    my ($sec,$min,$hour,$mday,
                            $mon,$year,$wday,$yday,$isdst) = gmtime($stamp);
                    $filename = sprintf "%04d-%02d-%02d_%02d-%02d-%02d",
                        ($year+1900), ($mon+1), $mday, $hour, $min, $sec;
   
                    $filename .= 'Z,' . $config->{yatg}->{interval};
                    $offset = 0;
                }   
                else {
                    $filename = (sort @files)[-1];
                    $filename =~ s#$root/$device/$leaf/$mport/##;
                    $filename
                 =~ m/^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)(Z?),(\d+)$/;
    
                    my $base_time = $7 ?
                        timegm($6,$5,$4,$3,$2-1,$1-1900) :
                        timelocal($6,$5,$4,$3,$2-1,$1-1900);
                    my $interval  = $8;

                    $offset = (($stamp - $base_time) / $interval);
                }   
    
                tie @store, 'Tie::File::FixedRecLen::Store',
                            "$root/$device/$leaf/$mport/$filename",
                            record_length => 20;
                next unless tied @store;

                eval { $store[$offset] = $data{$port} };
                untie @store;
            }
        }
    }

    return 1;
}

1;

# ABSTRACT: Back-end module to store polled data to disk


__END__
=pod

=head1 NAME

YATG::Store::Disk - Back-end module to store polled data to disk

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

This module implements part of a callback handler used to store SNMP data to
disk quickly, although not necessarily compactly. Disk is cheaper than CPU,
after all.

Our recommendation is that disk-based storage only be used with Interface
Indexed SNMP OIDs. The module will work with other results but retrieval will
be a bit messier, and we have not really tested it.

Given a location on your filesystem, each result of the poll of each SNMP OID
is written to a file. There is one file per OID per "port" per device. In this
context "port" might be a real network interface such as C<GigabitEthernet5/1>
or an index, if say the values are CPU loads and there are a few CPUs.

Input to the module is a data structure with SNMP poll results, like so:

 $results->{ip}->{leaf}->{port} = {value}

And then the C<value> will get written to a file:

 $root/ip/leaf/port/$timestamp,$interval

Here, C<$root> is set in the configuration (see below). The port name is
munged to translate non-alphanumeric characters to a dot (so it's
filesystem-safe on common OSes). The C<$timestamp> is set when the file is
created (if it's the first storage for this ip/leaf/port combination), and the
C<$interval> is read from the C<yatg_updater> configuration as the SNMP
polling interval.

With this data encoded in the filename and path, the content of the file is
each value on its own line. The timestamp of the first line in the file is
that of the filename, and each subsequent line is an C<$interval> in the
future from that. The file is padded out when there are missing data values.

Most of this you don't really need to worry about, because you get data back
using the L<YATG::Retrieve::Disk> module.

=head1 REQUIREMENTS

Install the following additional modules to use this plugin:

=over 4

=item *

L<Tile::File::FixedRecLen>

=item *

L<integer>

=item *

L<Time::Local>

=item *

L<Fcntl>

=back

=head1 CONFIGURATION

The only configuration you need to provide is for the file path of the
C<$root> for data storage. Set this in the main configuration, the default
being C</var/lib/yatg>:

 yatg:
     disk_root: '/tmp/yatg'

Note that the user under which the C<yatg_updater> process runs must be able
to create files and directories and write to them in this location.

=head1 SEE ALSO

=over 4

=item L<Tie::File::FixedRecLen::Store>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

