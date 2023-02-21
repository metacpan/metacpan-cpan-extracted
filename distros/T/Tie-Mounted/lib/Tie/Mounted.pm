package Tie::Mounted;

use strict;
use warnings;
use base qw(Tie::Array);
use boolean qw(true false);

use Carp qw(croak);
use File::Which ();
use IO::File ();

our ($VERSION, $FSTAB, $MOUNT_BIN, $UMOUNT_BIN, $NO_FILES);

$VERSION = '0.20';
$FSTAB = '/etc/fstab';
$MOUNT_BIN  = '/sbin/mount';
$UMOUNT_BIN = '/sbin/umount';

{
    sub TIEARRAY
    {
        my $class = shift;

        _gather_paths();
        _validate_node($_[0]);

        return bless _tie(@_), $class;
    }

    sub FETCHSIZE { $#{$_[0]} }           # FETCHSIZE, FETCH: Due to the node,
    sub FETCH     { $_[0]->[++$_[1]] }    # which is being kept hideously, accordingly
                                          # subtract (FETCHSIZE) or add (FETCH) 1.

    *STORESIZE = *STORE = sub { croak 'Tied array is read-only' };

    sub UNTIE { _umount($_[0]->[0]) }
}

sub _gather_paths
{
    my $locate = sub
    {
        my ($target, $path) = @_;

        unless (-e $$path && -x _) {
            my $which = File::Which::which($target);
            croak "Cannot locate `$target': $!" unless defined $which;
            $$path = $which;
        }
    };

    $locate->('mount',  \$MOUNT_BIN);
    $locate->('umount', \$UMOUNT_BIN);
}

sub _validate_node
{
    my ($node) = @_;

    my $fh = IO::File->new("<$FSTAB") or croak "Cannot open `$FSTAB' for reading: $!";
    my $fstabs = do { local $/; <$fh> };
    $fh->close;

    if (not defined $node && length $node) {
        croak 'No node supplied';
    }
    elsif (!-e $node) {
        croak "$node does not exist";
    }
    elsif (!-d $node) {
        croak "$node is not a directory";
    }
    elsif ($fstabs =~ /^\#.*?\s$node\s/m) {
        croak "$node is enlisted as disabled in $FSTAB";
    }
    elsif ($fstabs !~ /\s$node\s/) {
        croak "$node is not enlisted in $FSTAB";
    }
}

sub _tie
{
    my $node = shift;
    my @args = split /\s+/, defined $_[0] ? $_[0] : '';

    _mount($node, grep !/^-[aAd]$/o, @args);

    my $items = $NO_FILES ? [] : _read_dir($node);

    # Invisible node at index 0
    unshift @$items, $node;

    return $items;
}

sub _mount
{
    my $node = shift;

    unless (_is_mounted($node)) {
        system("$MOUNT_BIN @_ $node") == 0 or exit(1);
    }
}

sub _is_mounted
{
    my ($node) = @_;

    open(my $pipe, "$MOUNT_BIN |") or croak "Cannot open pipe to `$MOUNT_BIN': $!";
    my $ret_val = (scalar grep /\s$node\s/, <$pipe>) ? true : false;
    close($pipe) or croak "Cannot close pipe to `$MOUNT_BIN': $!";

    return $ret_val;
}

sub _read_dir
{
    my ($node) = @_;

    opendir(my $dh, $node) or croak "Cannot open directory `$node': $!";
    my @items = grep !/^\.\.?$/, sort readdir($dh);
    closedir($dh) or croak "Cannot close directory `$node': $!";

    return [ @items ];
}

sub _umount
{
    my ($node) = @_;

    if (_is_mounted($node)) {
        system("$UMOUNT_BIN $node") == 0 or exit(1);
    }
}

1;
__END__

=head1 NAME

Tie::Mounted - Tie a mounted node to an array

=head1 SYNOPSIS

 use Tie::Mounted;

 tie @files, 'Tie::Mounted', '/backup', '-v';
 print $files[-1];
 untie @files;

=head1 DESCRIPTION

This module ties files (and directories) of a mount point to an
array by invoking the system commands C<mount> and C<umount>;
C<mount> is invoked when a former attempt to tie an array is
being committed, C<umount> when a tied array is to be untied.
Suitability is therefore limited and suggests a rarely
used node (such as F</backup>, for example).

The mandatory parameter consists of the node (or: I<mount point>)
to be mounted (F</backup> - as declared in F</etc/fstab>);
options to C<mount> may be subsequently passed (C<-v>).
Device names and mount options (C<-a,-A,-d>) will be discarded
for safety's sake.

Default paths to C<mount> and C<umount> may be overriden
by setting accordingly either C<$Tie::Mounted::MOUNT_BIN> or
C<$Tie::Mounted::UMOUNT_BIN>. If one of them does not exist
at the predefined path, a C<which()> will be performed to
determine the actual path.

If C<$Tie::Mounted::NO_FILES> is set to a true value,
a bogus array with zero files will be tied.

=head1 BUGS & CAVEATS

=head2 Security

There are no security restrictions; it is recommended to
adjust filesystem permissions to prevent malicious use.

=head2 Portability

C<Tie::Mounted> is Linux/UNIX centered (due to the F<fstab> file
and the C<(u)mount> binary requirement) and will most likely
not work on other platforms.

=head2 Miscellanea

The tied array is read-only.

Files within the tied array are statically tied.

=head2 Lacking tests

Tests that test the base functionality are completely missing due to an
environment that most likely cannot be adequately simulated.

=head1 SEE ALSO

L<perlfunc/tie>, fstab(5), mount(8), umount(8)

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
