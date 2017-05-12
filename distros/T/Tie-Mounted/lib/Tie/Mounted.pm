package Tie::Mounted;

use strict;
use warnings;
use base qw(Tie::Array);

use Carp qw(croak);
use File::Which ();
use IO::File ();
use Symbol qw(gensym);

our ($VERSION, $FSTAB, $MOUNT_BIN, $UMOUNT_BIN, $NO_FILES);

$VERSION = '0.18';
$FSTAB = '/etc/fstab';
$MOUNT_BIN  = '/sbin/mount';
$UMOUNT_BIN = '/sbin/umount';

sub _private
{
    my $APPROVE = 0;
    my @NODES   = qw(    );

    return eval do { $_[0] };
}

{
    sub TIEARRAY
    {
        my $class = shift;

        _gather_paths();
        _validate_node($_[0]);

        return bless &_tie, $class;
    }

    sub FETCHSIZE { $#{$_[0]} }           # FETCHSIZE, FETCH: Due to the node,
    sub FETCH     { $_[0]->[++$_[1]] }    # which is being kept hideously, accordingly
                                          # subtract (FETCHSIZE) or add (FETCH) 1.
    *STORESIZE = *STORE =
      sub { croak 'Tied array is read-only' };

    sub UNTIE { _approve('umount', $_[0]->[0]) }
}

sub _gather_paths
{
    my $which_bin = sub
    {
        my ($target_var_name, $target) = @_;

        no strict 'refs';
        unless (-e ${$target_var_name} && -x _) {
            eval { require File::Basename };
            die $@ if $@;
            my $which = File::Which::which($target);
            defined $which
              ? ${$target_var_name} = $which
              : croak "Can't locate '", File::Basename::basename(${$target_var_name}), "': $!";
        }
    };

    $which_bin->('MOUNT_BIN', 'mount');
    $which_bin->('UMOUNT_BIN', 'umount');
}

sub _validate_node
{
    my ($node) = @_;

    my $fh = IO::File->new("<$FSTAB") or die "Can't open $FSTAB for reading: $!";
    my $fstabs = do { local $/; <$fh> };
    $fh->close;

    !$node
      ? croak 'No node supplied'
      : !-d $node
        ? croak "$node doesn't exist in $FSTAB"
        : $fstabs =~ /^\#.*$node/m
          ? croak "$node is enlisted as disabled in $FSTAB"
          : $fstabs !~ /$node/s
            ? croak "$node is not enlisted in $FSTAB"
            : '';
}

sub _tie
{
    my $node = shift;
    my @args = split /\s+/, $_[0];

    _approve('mount', $node, grep !/^-[aAd]$/o, @args);

    my $items = $NO_FILES ? [] : _read_dir($node);

    # Invisible node at index 0
    unshift @$items, $node;

    return $items;
}

sub _approve
{
    my ($sub, $node) = (shift, @_);

    if (_private('$APPROVE')) {
        croak "Attempt to $sub unapproved node"
          unless (grep { $node eq $_ } _private('@NODES'));
    }

    no strict 'refs';
    &{"_$sub"};
}

sub _mount
{
    my $node = shift;

    unless (_is_mounted($node)) {
        my $cmd = "$MOUNT_BIN @_ $node";
        system($cmd) == 0 or exit(1);
    }
}

sub _is_mounted
{
    my ($node) = @_;

    my $pipe = gensym();

    open($pipe, "$MOUNT_BIN |")
      or die "Can't init pipe to $MOUNT_BIN: $!";

    my $retval = (grep /$node/, <$pipe>) ? 1 : 0;

    close($pipe);

    return $retval;
}

sub _read_dir
{
    my ($node) = @_;

    my $dh = gensym();

    opendir($dh, $node)
      or die "Can't open directory $node: $!";

    my @items = grep !/^(?:\.|\.\.)$/, sort readdir($dh);

    closedir($dh);

    return \@items;
}

sub _umount
{
    my ($node) = @_;

    my $cmd = "$UMOUNT_BIN $node";
    system($cmd) == 0 or exit(1);
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
optional options to C<mount> may be subsequently passed (C<-v>).
Device names and mount options (C<-a,-A,-d>) will be discarded
in regard of system security.

Default paths to C<mount> and C<umount> may be overriden
by setting accordingly either C<$Tie::Mounted::MOUNT_BIN> or
C<$Tie::Mounted::UMOUNT_BIN>. If either of them doesn't exist
at the predefined path, a C<which()> will be performed to
determine the actual path.

If C<$Tie::Mounted::NO_FILES> is set to a true value,
a bogus array with zero files will be tied.

=head1 BUGS & CAVEATS

=head2 Security

C<Tie::Mounted> has by default set C<$APPROVE> to an untrue value in order
to allow all nodes to be passed. If C<$APPROVE> is set to a true value,
C<@NODES> has to contain the nodes that are considered ``approved"; both
variables are lexically scoped and adjustable within C<_private()>. If in
approval mode and a node is passed that is considered unapproved,
C<Tie::Mounted> will throw an exception.

Such ``security" is rather trivial; instead it is recommended
to adjust filesystem permissions to prevent malicious use.

=head2 Portability

C<Tie::Mounted> is Linux/UNIX centered (due to the F<fstab> file & the
C<mount/umount> binaries requirements) and will most likely won't work
on other platforms.

=head2 Miscellanea

The tied array is read-only.

Files within the tied array are statically tied.

=head2 Lacking tests

Tests that test the base functionality are completely missing due to an
environment that most likely can't be adequately simulated.

=head1 SEE ALSO

L<perlfunc/tie>, fstab(5), mount(8), umount(8)

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
