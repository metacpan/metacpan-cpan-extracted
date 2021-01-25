package Wireguard::WGmeta::Utils;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';
use base 'Exporter';
our @EXPORT = qw(read_dir read_file generate_ip_list);


sub read_dir($path, $pattern) {
    opendir(DIR, $path) or die "Could not open $path\n";
    my @files;

    while (my $file = readdir(DIR)) {
        if ($file =~ $pattern) {
            push @files, $path . $file;
        }
    }
    closedir(DIR);
    return @files;
}

=head3 read_file($path)

Reads a file given by a C<$path> into a string

B<Parameters>

=over 1

=item

C<$path> Path to file

=back

B<Raises>

Exception if the file is somehow inaccessible.

B<Returns>

File contents as string

=cut
sub read_file($path) {
    open my $fh, '<', $path or die "Can't open `$path`: $!";
    my $file_content = do {
        local $/;
        <$fh>
    };
    return $file_content;
}

sub generate_ip_list($network_id, $subnet_size) {
    # thanks to https://www.perl.com/article/creating-ip-address-tools-from-scratch/

    my %ip_list;
    my @bytes = split /\./, $network_id;
    my $start_decimal = $bytes[0] * 2 ** 24 + $bytes[1] * 2 ** 16 + $bytes[2] * 2 ** 8 + $bytes[3];
    my $bits_remaining = 32 - $subnet_size;
    my $end_decimal = $start_decimal + 2 ** $bits_remaining - 1;

    while ($start_decimal <= $end_decimal) {
        my @bytes = unpack 'CCCC', pack 'N', $start_decimal;
        my $ipv4 = (join '.', @bytes).'/32' ;
        $ip_list{$ipv4} = undef;
        $start_decimal++;
    }
    return \%ip_list;
}

1;