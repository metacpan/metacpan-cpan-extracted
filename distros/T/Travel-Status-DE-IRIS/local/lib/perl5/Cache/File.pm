=head1 NAME

Cache::File - Filesystem based implementation of the Cache interface

=head1 SYNOPSIS

  use Cache::File;

  my $cache = Cache::File->new( cache_root => '/tmp/mycache',
                                default_expires => '600 sec' );

See Cache for the usage synopsis.

=head1 DESCRIPTION

The Cache::File class implements the Cache interface.  This cache stores
data in the filesystem so that it can be shared between processes and persists
between process invocations.

=cut
package Cache::File;

require 5.006;
use strict;
use warnings;
use Cache::File::Heap;
use Cache::File::Entry;
use Digest::SHA qw(sha1_hex);
use Fcntl qw(LOCK_EX LOCK_NB);
use Symbol ();
use File::Spec;
use File::Path;
use File::NFSLock;
use DB_File;
use Storable;
use Carp;

use base qw(Cache);
use fields qw(
    root depth umask locklevel
    expheap ageheap useheap index lockfile
    lock lockcount openexp openage openuse openidx);

our $VERSION = '2.11';

sub LOCK_NONE ()  { 0 }
sub LOCK_LOCAL () { 1 }
sub LOCK_NFS ()   { 2 }


my $DEFAULT_DEPTH = 2;
my $DEFAULT_UMASK = 077;
my $DEFAULT_LOCKLEVEL = LOCK_NFS;

my $INDEX       = 'index.db';
my $EXPIRY_HEAP = 'expheap.db';
my $AGE_HEAP    = 'ageheap.db';
my $USE_HEAP    = 'useheap.db';
my $LOCKFILE    = 'lock';

our $STALE_LOCK_TIMEOUT = 30;  # 30 second timeout on lockfiles
our $LOCK_EXT   = '.lock';

# keys to store count and size in the index
my $SIZE_KEY  = '__cache_size';
my $COUNT_KEY = '__cache_count';


=head1 CONSTRUCTOR

  my $cache = Cache::File->new( %options )

The constructor takes cache properties as named arguments, for example:

  my $cache = Cache::File->new( cache_root => '/tmp/mycache',
                                lock_level => Cache::File::LOCK_LOCAL(),
                                default_expires => '600 sec' );

Note that you MUST provide a cache_root property.

See 'PROPERTIES' below and in the Cache documentation for a list of all
available properties that can be set.

=cut

sub new {
    my Cache::File $self = shift;
    my $args = $#_? { @_ } : shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($args);

    $self->_set_cache_lock_level($args->{lock_level});
    $self->_set_cache_umask($args->{cache_umask});
    $self->_set_cache_depth($args->{cache_depth});
    $self->_set_cache_root($args->{cache_root});

    return $self;
}

=head1 METHODS

See 'Cache' for the API documentation.

=cut

sub entry {
    my Cache::File $self = shift;
    my ($key) = @_;
    return Cache::File::Entry->new($self, $key);
}

sub purge {
    my Cache::File $self = shift;
    my $time = time();

    # if it's locked, someone else will probably be doing a purge already
    $self->trylock() or return;

    # open expiry index
    my $expheap = $self->get_exp_heap();

    # check for expiry
    my $minimum = $expheap->minimum();
    if ($minimum and $minimum <= $time) {
        # open other indexes
        my $ageheap = $self->get_age_heap();
        my $useheap = $self->get_use_heap();
        my $index = $self->get_index();

        # loop removing minimums
        do {
            my $keys;
            ($minimum, $keys) = $expheap->extract_minimum_dup();

            foreach (@$keys) {
                # update all the indexes (remove references to this key)
                my $path = $self->cache_file_path($_);

                my $index_entries = $self->get_index_entries($_)
                    or warnings::warnif('Cache', "missing index entry for $_");
                delete $$index{$_};

                $ageheap->delete($$index_entries{age}, $_)
                    if $$index_entries{age};
                $useheap->delete($$index_entries{lastuse}, $_)
                    if $$index_entries{lastuse};

                # reduce the cache size and count
                $$index{$COUNT_KEY}--;
                $$index{$SIZE_KEY} -= (-s $path);

                # remove data file
                unlink($path);
            }

            $minimum = $expheap->minimum();

        } while ($minimum and $minimum <= $time);
    }

    $self->unlock();
}

sub clear {
    my Cache::File $self = shift;
    my $fh = Symbol::gensym();

    $self->lock();

    # Find each directory entries are stored in and remove them
    opendir($fh, $self->{root})
        or die "Can't opendir ".$self->{root}.": $!";
    my @stores =
        grep { -d $_ }
        map { File::Spec->catdir($self->{root}, $_) }
    File::Spec->no_upwards(readdir($fh));
    closedir($fh);

    rmtree(\@stores,0,1);

    # remove the index files
    unlink($self->{expheap});
    unlink($self->{ageheap});
    unlink($self->{useheap});
    unlink($self->{index});

    $self->unlock();
}

sub count {
    my Cache::File $self = shift;

    my $count;
    $self->lock();
    my $index = $self->get_index();
    $count = $$index{$COUNT_KEY};
    $self->unlock();

    return $count || 0;
}

sub size {
    my Cache::File $self = shift;

    my $size;
    $self->lock();
    my $index = $self->get_index();
    $size = $$index{$SIZE_KEY};
    $self->unlock();

    return $size || 0;
}

sub sync {
    my Cache::File $self = shift;
    # TODO: check entries in cache root and rebuild heaps
}


=head1 PROPERTIES

Cache::File adds the following properties in addition to those discussed in
the 'Cache' documentation.

=over

=item cache_root

Used to specify the location of the cache store directory.  All methods will
work ONLY data stored within this directory.  This parameter is REQUIRED when
creating a Cache::File instance.

 my $ns = $c->cache_root();

=cut

sub cache_root {
    my Cache::File $self = shift;
    return $self->{root};
}

sub _set_cache_root {
    my Cache::File $self = shift;
    my ($cache_root) = @_;
    $cache_root or croak 'A cache root directory MUST be provided';
    $self->{root} = File::Spec->canonpath(
        File::Spec->rel2abs($cache_root, File::Spec->tmpdir()));

    # create root
    unless (-d $self->{root}) {
        my $oldmask = umask $self->cache_umask();
        eval { mkpath($self->{root}) }
            or die 'Failed to create cache root '.$self->{root}.": $@";
        umask $oldmask;
    }

    # set required file paths
    $self->{expheap} = File::Spec->catfile($self->{root}, $EXPIRY_HEAP);
    $self->{ageheap} = File::Spec->catfile($self->{root}, $AGE_HEAP);
    $self->{useheap} = File::Spec->catfile($self->{root}, $USE_HEAP);
    $self->{index} = File::Spec->catfile($self->{root}, $INDEX);
    $self->{lockfile} = File::Spec->catfile($self->{root}, $LOCKFILE);
}

=item cache_depth

The number of subdirectories deep to store cache entires.  This should be
large enough that no cache directory has more than a few hundred object.
Defaults to 2 unless explicitly set.

 my $depth = $c->cache_depth();

=cut

sub cache_depth {
    my Cache::File $self = shift;
    return $self->{depth};
}

sub _set_cache_depth {
    my Cache::File $self = shift;
    my ($cache_depth) = @_;
    $self->{depth} = (defined $cache_depth)? $cache_depth : $DEFAULT_DEPTH;
}

=item cache_umask

Specifies the umask to use when creating entries in the cache directory.  By
default the umask is '077', indicating that only the same user may access
the cache files.

 my $umask = $c->cache_umask();

=cut

sub cache_umask {
    my Cache::File $self = shift;
    return $self->{umask};
}

sub _set_cache_umask {
    my Cache::File $self = shift;
    my ($cache_umask) = @_;
    $self->{umask} = (defined $cache_umask)? $cache_umask : $DEFAULT_UMASK;
}

=item lock_level

Specify the level of locking to be used.  There are three different levels
available:

=item Cache::File::LOCK_NONE()

No locking is performed.  Useful when you can guarantee only one process will
be accessing the cache at a time.

=item Cache::File::LOCK_LOCAL()

Locking is performed, but it is not suitable for use over NFS filesystems.
However it is more efficient.

=item Cache::File::LOCK_NFS()

Locking is performed in a way that is suitable for use on NFS filesystems.

=back

 my $level = $c->cache_lock_level();

=cut

sub cache_lock_level {
    my Cache::File $self = shift;
    return $self->{locklevel};
}

sub _set_cache_lock_level {
    my Cache::File $self = shift;
    my ($locklevel) = @_;

    if (defined $locklevel) {
        croak "Unknown lock level requested"
            unless ($locklevel =~ /^[0-9]+$/ &&
                    ($locklevel == LOCK_NONE ||
                     $locklevel == LOCK_LOCAL ||
                     $locklevel == LOCK_NFS));
    } else {
        $locklevel = $DEFAULT_LOCKLEVEL;
    }

    $self->{locklevel} = $locklevel;
}


# REMOVAL STRATEGY METHODS

sub remove_oldest {
    my Cache::File $self = shift;

    # Only called from check_size (via change_size) when the lock is set
    #$self->lock();
    my $ageheap = $self->get_age_heap();

    my ($minimum, $key) = $ageheap->extract_minimum();
    $key or return undef;
    my $size = $self->remove($key);
    #$self->unlock();
    return $size;
}

sub remove_stalest {
    my Cache::File $self = shift;

    # Only called from check_size (via change_size) when the lock is set
    #$self->lock();
    my $useheap = $self->get_use_heap();

    my ($minimum, $key) = $useheap->extract_minimum();
    $key or return undef;
    my $size = $self->remove($key);
    #$self->unlock();
    return $size;
}


# UTILITY METHODS

sub cache_file_path {
    my Cache::File $self = shift;
    my ($key) = @_;

    my $shakey = sha1_hex($key);
    my (@path) = unpack('A2'x$self->{depth}.'A*', $shakey);

    if (wantarray) {
        my $file = pop(@path);
        return (File::Spec->catdir($self->{root}, @path), $file);
    } else {
        return File::Spec->catfile($self->{root}, @path);
    }
}

sub lock {
    my Cache::File $self = shift;
    my ($tryonly) = @_;

    # already have the lock?
    if ($self->{lock}) {
        $self->{lockcount}++;
        return 1;
    }

    if ($self->{locklevel} == LOCK_NONE) {
        $self->{lock} = 1;
    }
    else {
        # TODO: implement LOCK_LOCAL

        my $oldmask = umask $self->cache_umask();
        my $lock = File::NFSLock->new({
                file                => $self->{lockfile},
                lock_type           => LOCK_EX | ($tryonly? LOCK_NB : 0),
                stale_lock_timeout  => $STALE_LOCK_TIMEOUT,
            });
        umask $oldmask;

        unless ($lock) {
            $tryonly and return 0;
            die "Failed to obtain lock on lockfile '".$self->{lockfile}."': ".
                $File::NFSLock::errstr."\n";
        }
        $self->{lock} = $lock;
    }

    $self->{lockcount} = 1;
    return 1;
}

sub trylock {
    my Cache::File $self = shift;
    return $self->lock(1);
}

sub unlock {
    my Cache::File $self = shift;
    $self->{lock} or croak "not locked";
    return unless --$self->{lockcount} == 0;

    # close heaps and save counts
    $self->{openexp} = undef;
    $self->{openage} = undef;
    $self->{openuse} = undef;
    $self->{openidx} = undef;

    # unlock
    $self->{lock}->unlock unless $self->{locklevel} == LOCK_NONE;
    $self->{lock} = undef;
}

sub create_entry {
    my Cache::File $self = shift;
    my ($key, $time) = @_;

    my $ageheap = $self->get_age_heap();
    $ageheap->add($time, $key);
    my $useheap = $self->get_use_heap();
    $useheap->add($time, $key);

    $self->set_index_entries($key, { age => $time, lastuse => $time });
}

sub update_last_use {
    my Cache::File $self = shift;
    my ($key, $time) = @_;

    my $index_entries = $self->get_index_entries($key)
        or warnings::warnif('Cache', "missing index entry for $key");

    my $useheap = $self->get_use_heap();
    $useheap->delete($$index_entries{lastuse}, $key);
    $useheap->add($time, $key);

    $$index_entries{lastuse} = $time;
    $self->set_index_entries($key, $index_entries);
}

sub change_count {
    my Cache::File $self = shift;
    my ($count) = @_;
    my $index = $self->get_index();
    my $oldcount = $$index{$COUNT_KEY};
    $$index{$COUNT_KEY} = $oldcount? $oldcount + $count : $count;
}

sub change_size {
    my Cache::File $self = shift;
    my ($size) = @_;
    my $index = $self->get_index();
    my $oldsize = $$index{$SIZE_KEY};
    $$index{$SIZE_KEY} = $oldsize? $oldsize + $size : $size;
    $self->check_size($$index{$SIZE_KEY}) if $size > 0;
}

sub get_index_entries {
    my Cache::File $self = shift;
    my ($key) = @_;

    my $index = $self->get_index();
    my $index_entry = $$index{$key}
        or return undef;

    my $index_entries = Storable::thaw($index_entry);
    $$index_entries{age} and $$index_entries{lastuse}
        or warnings::warnif('Cache', "invalid index entry for $_");

    return $index_entries;
}

sub set_index_entries {
    my Cache::File $self = shift;
    my $key = shift;
    my $index_entries = $#_? { @_ } : shift;

    $$index_entries{age} and $$index_entries{lastuse}
        or croak "failed to supply age and lastuse for index update on $key";

    my $index = $self->get_index();
    $$index{$key} = Storable::nfreeze($index_entries);
}

sub get_index {
    my Cache::File $self = shift;
    unless ($self->{openidx}) {
        $self->{lock} or croak "not locked";

        my $indexfile = $self->{index};
        File::NFSLock::uncache($indexfile) if $self->{locklevel} == LOCK_NFS;

        my $oldmask = umask $self->cache_umask();
        my %indexhash;
        my $index =
            tie %indexhash, 'DB_File', $indexfile,O_CREAT|O_RDWR,0666,$DB_HASH;
        umask $oldmask;

        $index or die "Failed to open index $indexfile: $!";

        $self->{openidx} = \%indexhash;
    }
    return $self->{openidx};
}

sub get_exp_heap {
    my Cache::File $self = shift;
    return $self->{openexp} ||= $self->_open_heap($self->{expheap});
}

sub get_age_heap {
    my Cache::File $self = shift;
    return $self->{openage} ||= $self->_open_heap($self->{ageheap});
}

sub get_use_heap {
    my Cache::File $self = shift;
    return $self->{openuse} ||= $self->_open_heap($self->{useheap});
}

sub _open_heap {
    my Cache::File $self = shift;
    my ($heapfile) = @_;
    $self->{lock} or croak "not locked";

    File::NFSLock::uncache($heapfile) if $self->{locklevel} == LOCK_NFS;

    my $oldmask = umask $self->cache_umask();
    my $heap = Cache::File::Heap->new($heapfile);
    umask $oldmask;
    $heap or die "Failed to open heap $heapfile: $!";
    return $heap;
}


1;
__END__

=head1 CAVEATS

There are a couple of caveats in the current implementation of Cache::File.
None of these will present a problem in using the class, it's more of a TODO
list of things that could be done better.

=over

=item external cache modification (and re-syncronization)

Cache::File maintains indexes of entries in the cache, including the number of
entries and the total size.  Currently there is no process of checking that
the count or size are in syncronization with the actual data on disk, and thus
any modifications to the cache store by another program (eg. a user shell)
will result in an inconsitency in the index.  A better process would be for
Cache::File to resyncronize at an appropriate time (eg whenever the size or
count is initially requested - this would only need happen once per instance).
This resyncronization would involve calculating the total size and count as
well as checking that entries in the index accurately reflect what is on the
disk (and removing any entries that have dissapeared or adding any new ones).

=item index efficiency

Currently Berkeley DB's are used for indexes of expiry time, last use and entry
age.  They use the BTREE variant in order to implement a heap (see
Cache::File::Heap).  This is probably not the most efficient format and having
3 separate index files adds overhead.  These are also cross-referenced with
a fourth index file that uses a normal hash db and contains all these time
stamps (frozen together with the validity object to a single scalar via
Storable) indexed by key.  Needless to say, all this could be done more
efficiently - probably by using a single index in a custom format.

=item locking efficiency

Currently LOCK_LOCAL is not implemented (if uses the same code as LOCK_NFS).

There are two points of locking in Cache::File, index locking and entry
locking.  The index locking is always exclusive and the lock is required
briefly during most operations.  The entry locking is either shared or
exclusive and is also required during most operations.  When locking is
enabled, File::NFSLock is used to provide the locking for both situations.
This is not overly efficient, especially as the entry lock is only ever
grabbed whilst the index lock is held.

=back

=head1 SEE ALSO

Cache

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: File.pm,v 1.7 2006/01/31 15:23:58 caleishm Exp $

=cut
