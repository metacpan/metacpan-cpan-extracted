package Wireguard::WGmeta::Utils;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';
use Time::HiRes qw(stat);
use Digest::MD5 qw(md5);
use base 'Exporter';
our @EXPORT = qw(read_dir read_file write_file get_mtime compute_md5_checksum split_and_trim);

use constant LOCK_SH => 1;
use constant LOCK_EX => 2;

=head3 read_dir($path, $pattern)

Returns a list of all files in a director matching C<$pattern>

B<Parameters>

=over 1

=item

C<$path> Path to directory

=item

C<$pattern> Regex pattern (and make sure to escape with `qr` -> e.g I<qr/.*\.conf$/>)

=back

B<Returns>

A list of matching files, possibly empty

=cut
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

=head3 read_file($path [, $path_is_fh = undef])

Reads a file given by a C<$path> into a string. Applies a shared lock on the file while reading. C<$path> can also
reference an open filehandle for external control over locks and cursor. If this is the case, set C<$path_is_fh> to True.

B<Parameters>

=over 1

=item

C<$path> Path to file

=item

C[$path_is_fh = undef]> Set to True if C<$path> is an open filehandle (at least for reading).

=back

B<Raises>

Exception if the file is somehow inaccessible or it was unable to acquire the lock

B<Returns>

File contents as string

=cut
sub read_file($path, $path_is_fh = undef) {
    my $fh;
    unless (defined $path_is_fh) {
        open $fh, '<', $path or die "Can't open `$path`: $!";
        # try to get a shared lock
        flock $fh, LOCK_SH or die "Could not get shared lock on file `$path`: $!";
    }
    else {
        $fh = $path;
    }
    my $file_content = do {
        local $/;
        <$fh>
    };
    close $fh unless (defined $path_is_fh);
    return $file_content;
}

=head3 write_file($path, $content [, $path_is_fh = undef])

Writes C<$content> to C<$file> while having an exclusive lock. C<$path> can also
reference an open filehandle for external control over locks and cursor. If this is the case, set C<$path_is_fh> to True.

B<Parameters>

=over 1

=item

C<$path> Path to file

=item

C<$content> File content

=item

C<[$path_is_fh = undef]> Set to True if C<$path> is an open filehandle (write!)

=back

B<Raises>

Exception if the file is somehow inaccessible or it was unable to acquire the lock

B<Returns>

None

=cut
sub write_file($path, $content, $path_is_fh = undef) {
    my $fh;
    unless (defined $path_is_fh) {
        open $fh, '>', $path or die "Could not open `$path` for writing: $!";

        # try to get an exclusive lock
        flock $fh, LOCK_EX or die "Could not get an exclusive lock on file `$path`: $!";
    }
    else {
        $fh = $path;
    }
    print $fh $content;
    close $fh unless (defined $path_is_fh);
}

=head3 get_mtime($path)

Tries to extract mtime from a file. If supported by the system in milliseconds resolution.

B<Parameters>

=over 1

=item

C<$path> Path to file

=back

B<Returns>

mtime of the file. If something went wrong, "0";

=cut
sub get_mtime($path) {
    my @stat = stat($path);
    return (defined($stat[9])) ? "$stat[9]" : "0";
}

sub compute_md5_checksum($input) {
    my $str = substr(md5($input), 0, 4);
    return unpack 'L', $str; # Convert to 4-byte integer
}

=head3 split_and_trim($line, $separator)

Utility method to split and trim a string separated by C<$separator>.

B<Parameters>

=over 1

=item *

C<$line> Input string (e.g 'This = That   ')

=item *

C<$separator> String separator (e.v '=')

=back

B<Returns>

Two strings. With example values given in the parameters this would be 'This' and 'That'.

=cut
sub split_and_trim($line, $separator) {
    return map {s/^\s+|\s+$//g;
        $_} split $separator, $line, 2;
}


1;