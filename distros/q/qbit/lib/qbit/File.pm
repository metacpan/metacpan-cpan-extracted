
=head1 Name

qbit::File - Functions to manipulate files.

=cut

package qbit::File;
$qbit::File::VERSION = '2.5';
use strict;
use warnings;
use utf8;

use base qw(Exporter);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      readfile
      writefile
      );
    @EXPORT_OK = @EXPORT;
}

use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_APPEND);

use qbit::StringUtils;
use qbit::Exceptions;
use qbit::GetText;

=head1 Functions

=head2 readfile

B<Arguments:>

=over

=item

B<$filename> - string, file name;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<binary> - boolean, binary ? C<binmode($fh)> : C<binmode($fh, ':utf8')>.

=back

=back

B<Return value:> string, file content.

=cut

sub readfile($;%) {
    my ($filename, %opts) = @_;

    my $fh = local *FH;
    unless (sysopen($fh, $filename, O_RDONLY)) {
        throw Exception gettext('Cannot open file "%s": %s', $filename, qbit::StringUtils::fix_utf($!));
    }

    $opts{'binary'} ? binmode $fh : binmode $fh, ':utf8';

    my $size_left = -s $filename;

    my $content = '';
    while (1) {
        my $read_cnt = sysread($fh, $content, $size_left, length $content);

        unless (defined $read_cnt) {
            throw Exception gettext('Cannot read file "%s": %s', $filename, qbit::StringUtils::fix_utf($!));
        }

        last if $read_cnt == 0;

        $size_left -= $read_cnt;
        last if $size_left <= 0;
    }

    return $content;
}

=head2 writefile

B<Arguments:>

=over

=item

B<$filename> - string, file name;

=item

B<$data> - string, file content;

=item

B<%opts> - hash, additional arguments:

=over

=item

B<binary> - boolean, binary ? C<binmode($fh)> : C<binmode($fh, ':utf8')>.

B<append> - boolean

=back

=back

=cut

sub writefile($$;%) {
    my ($filename, $data, %opts) = @_;

    my $fh = local *FH;

    my $mode = O_WRONLY | O_CREAT;
    $mode |= O_APPEND if $opts{'append'};

    unless (sysopen($fh, $filename, $mode)) {
        throw Exception gettext('Cannot open file "%s" for write: %s', $filename, qbit::StringUtils::fix_utf($!));
    }

    $opts{'binary'} ? binmode $fh : binmode $fh, ':utf8';

    print $fh $data;

    close($fh);
}

1;
