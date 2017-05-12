package YATG::Retrieve::Disk;
{
  $YATG::Retrieve::Disk::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use Time::Local;
use Tie::File::FixedRecLen;
use Fcntl 'O_RDONLY';
use integer;

sub retrieve {
    my ($config, $device, $port, $leaf, $start, $end, $step) = @_;
    my $root = $config->{yatg}->{disk_root};

    $port ||= 1;
    $port =~ s/[^A-Za-z0-9]/./g; # just in case, re-squash port chars

    my @files = grep {m/\d{4}-\d\d-\d\d_\d\d-\d\d-\d\dZ?,\d+$/}
                     glob("$root/$device/$leaf/$port/*");
    die "File not found at '$root/$device/$leaf/$port'\n"
        if scalar @files == 0;

    my $filename = (sort @files)[-1];
    die "File '$filename' empty!\n" unless -s $filename;

    my @store;
    tie @store, 'Tie::File::FixedRecLen', $filename,
                mode => O_RDONLY, record_length => 20;
    die "Failed to Tie::File::FixedRecLen file at '$filename'\n"
        if !tied @store;

    $filename =~ s#$root/$device/$leaf/$port/##;
    $filename =~ m/^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)(Z?),(\d+)$/;

    my $base_time = $7 ?
        timegm($6,$5,$4,$3,$2-1,$1-1900) :
        timelocal($6,$5,$4,$3,$2-1,$1-1900);
    my $interval  = $8;
    my $top_time  = $base_time + ($#store * $interval);

    $step ||= $interval;
    $start = ($start - ($start % $step));
    $end   = ($end   - ($end   % $step));
    my $nudge = ($step / $interval);

    my $num_steps = (($end - $start) / $step);
    my @data = map {'0'} (0 .. ($num_steps - 1)); # fenceposts!

    my $data_offset_start =
        (($start < $base_time) ? (($base_time - $start) / $step) : 0);

    my $store_offset_start =
        (($start > $base_time) ? ((($start - $base_time) / $interval)) : 0);

    my @store_pad = map {$_} ($store_offset_start .. $#store);

    while (my @chunk = splice @store_pad,0,$nudge) {
        $data[$data_offset_start] = $store[ $chunk[-1] ] || 0;
        ++$data_offset_start;
        last if $data_offset_start > $#data;
    }

    untie @store;
    return \@data;
}

1;

# ABSTRACT: Retrieve a set of data stored by YATG::Store::Disk


__END__
=pod

=head1 NAME

YATG::Retrieve::Disk - Retrieve a set of data stored by YATG::Store::Disk

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

You can load this module to retrieve a set of data which has previously been
stored by YATG::Store::Disk. An implementation of this process is given in the
CGI bundled with this distribution, which displays results of SNMP polls.

For more information on the data storage format, see L<YATG::Store::Disk>.

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

=head1 USAGE

There is one subroutine, C<retrieve()> which takes seven parameters:

=over 4

=item C<config>

Load up your C<yatg_updater> config using the following idiom, and pass the
result in this parameter (assuming the file is named C<yatg.yml>):

 use YATG::Config;
 YATG::Config->Defaults->{'no_validation'} = 1;
 
 my $yatg_conf = YATG::Config->parse('yatg.yml')
     || die 'failed to load yatg config';
 
 # now pass in $yatg_conf

=item C<device>

This should be the IP address of a device.

=item C<port>

This should be the port name, for example C<GigabitEthernet5/1>.

=item C<leaf>

This should be the SNMP leaf name (and not the OID), for example
C<ifHCInOctets>.

=item C<start>

This should be a UNIX timestamp (i.e. seconds since the epoch) representing
the start point for retrieved results.

=item C<end>

This should be a UNIX timestamp (i.e. seconds since the epoch) representing
the end point for retrieved results.

=item C<step>

This parameter is optional. If not specified, the filename of the result set
encodes the polling interval which will then be used for the returned results
interval (i.e. one data point per C<step> seconds returned).

Alternatively you can pass a number of seconds in this parameter and the
module will do its best to provide one data point per C<step> seconds in the
returned results.

=back

The subroutine will die if it encounters difficulty opening the data file or
extracting results from it, so use an C<eval{};> construct or similar.

Otherwise, the return value is an array reference of results corresponding to
the data points you requested with start, end and step.

=head1 SEE ALSO

=over 4

=item L<Tie::File::FixedRecLen>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

