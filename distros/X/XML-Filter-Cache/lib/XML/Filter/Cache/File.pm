# $Id: File.pm,v 1.2 2002/01/28 15:17:27 matt Exp $

package XML::Filter::Cache::File;
use strict;

use vars qw($VERSION @ISA);
$VERSION = '0.02';

use XML::Filter::Cache ();
@ISA = qw(XML::Filter::Cache);

use Digest::MD5 qw(md5_hex);
use File::Spec ();
use Symbol ();

sub new {
    my $class = shift;
    my $opts = (@_ == 1) ? { %{shift(@_)} } : {@_};

    $opts->{CacheRoot} ||= File::Spec->tmpdir;

    return bless $opts, $class;
}

sub open {
    my ($self, $mode) = @_;
    
    my $key = md5_hex($self->{Key});
    my $primary = substr($key, 0, 2, '');
    my $secondary = substr($key, 0, 2, '');
    my $cacheroot = $self->{CacheRoot};
    my $filename = File::Spec->catdir($cacheroot, $primary, $secondary, $key);
    my $fh = Symbol::gensym();

    if ($mode eq 'w') {
        if (!open($fh, ">$filename")) {
            if (!-e $cacheroot) {
                if (!mkdir($cacheroot, 0777)) {
                    die "Cannot create cache directory '$cacheroot': $!";
                }
            }
            
            if (!-e File::Spec->catdir($cacheroot, $primary)) {
                if (!mkdir(File::Spec->catdir($cacheroot, $primary), 0777)) {
                    die "Cannot create primary directory '$cacheroot/$primary': $!";
                }
            }
    
            if (!-e File::Spec->catdir($cacheroot, $primary, $secondary)) {
                if (!mkdir(File::Spec->catdir($cacheroot, $primary, $secondary), 0777)) {
                    die "Cannot create secondary directory '$cacheroot/$primary/$secondary': $!";
                }
            }

            open($fh, ">$filename")
                || die "Cannot write to cache file '$filename': $!";
        }
            
        binmode($fh);
    }
    elsif ($mode eq 'r') {
        open($fh, "<$filename") || die "Cannot read cache file '$filename': $!";
        binmode($fh);
    }
    $self->{fh} = $fh;
    $self->{filename} = $filename;
}

sub close {
    my $self = shift;
    close($self->{fh});
}

sub _read {
    my $self = shift;
    my $fh = $self->{fh};
    return if eof($fh);
    my $buff;
    if (read($fh, $buff, 4) != 4) {
        die "Broken cache file '$self->{filename}'";
    }
    my $length = unpack("L", $buff);
    if (read($fh, $buff, $length) != $length) {
        die "Broken cache file '$self->{filename}'";
    }
    my $record = unpack("a*", $buff);
    return $record;
}

sub _write {
    my ($self, $frozen) = @_;
    my $fh = $self->{fh};
    my $out = pack("La*", length($frozen), $frozen);
    print $fh $out;
}

1;
__END__

=head1 NAME

XML::Filter::Cache::File - Filesystem based caching implementation

=head1 DESCRIPTION

This default cache plugin module uses a file on the filesystem to store
the cached events. It simply does an MD5 hash of the Key (either passed
in or created from the SystemId), and stores that under CacheRoot. It
also uses a two-part directory system to speed things up under ext2fs.

=head1 PARAMETERS

=over 4

=item CacheRoot

Pass this in to XML::Filter::Cache->new() to change the default cache
directory from File::Spec->tmpdir to something different.

=item Key

This specifies a unique key to use in constructing the cache.

=back

=head1 SEE ALSO

L<XML::Filter::Cache>.

=cut
