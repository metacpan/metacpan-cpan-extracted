
=head1 Name

qbit::File - Functions to manipulate files.

=cut

package qbit::File;
$qbit::File::VERSION = '2.4';
use strict;
use warnings;
use utf8;

require qbit::StringUtils;

use base qw(Exporter);

use Data::Dumper;

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      readfile
      writefile
      );
    @EXPORT_OK = @EXPORT;
}

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

    open(my $fh, '<', $filename) || die "Cannot open file \"$filename\": " . qbit::StringUtils::fix_utf($!);
    $opts{'binary'} ? binmode($fh) : binmode($fh, ':utf8');
    my $data = join('', <$fh>);
    close($fh);

    return $data;
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

    my $mode = $opts{'append'} ? '>>' : '>';

    open(my $fh, $mode, $filename) || die "Cannot open file \"$filename\" for write: " . qbit::StringUtils::fix_utf($!);
    $opts{'binary'} ? binmode($fh) : binmode($fh, ':utf8');
    print $fh $data;
    close($fh);
}

1;
