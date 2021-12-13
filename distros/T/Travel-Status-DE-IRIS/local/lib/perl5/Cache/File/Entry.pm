=head1 NAME

Cache::File::Entry - An entry in the file based implementation of Cache

=head1 SYNOPSIS

  See 'Cache::Entry' for a synopsis.

=head1 DESCRIPTION

This module implements a version of Cache::Entry for the Cache::File variant
of Cache.  It should not be created or used directly, please see
'Cache::File' or 'Cache::Entry' instead.

=cut
package Cache::File::Entry;

require 5.006;
use strict;
use warnings;
use Cache::File;
use File::Spec;
use File::Path;
use File::Temp qw(tempfile);
use Fcntl qw(LOCK_EX LOCK_SH LOCK_NB);
use File::NFSLock;
use Symbol ();
use Carp;

use base qw(Cache::Entry);
use fields qw(dir path lockdetails);

our $VERSION = '2.11';

# hash of locks held my the process, keyed on path.  This is useful for
# catching potential deadlocks and warning the user, and for implementing
# LOCK_NONE (which still needs to do some synchronization).  Each entry will
# be an hash of { lock, type, count, lock, lockfh, linkcount }.  The
# filehandle and link count is for checking when the lock has been released by
# another process.
my %PROCESS_LOCKS;


sub new {
    my Cache::File::Entry $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    # get file path and store full path and containing directory
    my ($dir, $file) = $self->{cache}->cache_file_path($self->{key});

    $self->{dir} = $dir;
    $self->{path} = File::Spec->catfile($dir, $file);

    return $self;
}

sub exists {
    my Cache::File::Entry $self = shift;

    # ensure pending expiries are removed
    $self->{cache}->purge();

    return -e $self->{path};
}

sub _set {
    my Cache::File::Entry $self = shift;
    my ($data, $expiry) = @_;

    $self->_make_path() or return;

    my ($fh, $filename) = tempfile('.XXXXXXXX', DIR => $self->{dir});
    binmode $fh;
    print $fh $data;
    close($fh);

    my $time = time();
    my $cache = $self->{cache};
    my $key = $self->{key};

    # lock indexes
    $cache->lock();

    my $exists = -e $self->{path};
    my $orig_size;

    unless ($exists) {
        # we're creating the entry
        $cache->create_entry($key, $time);
        $cache->change_count(1);
        $orig_size = 0;
    }
    # only remove current size if there is no active write handle
    elsif ($self->_trylock(LOCK_SH)) {
        $orig_size = $self->size();
        $self->_unlock();
    }
    else {
        $orig_size = 0;
    }

    # replace existing data
    rename($filename, $self->{path});

    # fix permissions of tempfile
    my $mode = 0666 & ~($self->{cache}->cache_umask());
    chmod $mode, $self->{path};

    # invalidate any active handle locks
    unlink($self->{path} . $Cache::File::LOCK_EXT);
    delete $PROCESS_LOCKS{$self->{path}};

    $self->_set_expiry($expiry) if $expiry or $exists;
    $cache->update_last_use($key, $time) if $exists;

    $cache->change_size($self->size() - $orig_size);
    # ensure pending expiries are removed
    $cache->purge();

    $cache->unlock();
}

sub _get {
    my Cache::File::Entry $self = shift;

    my $cache = $self->{cache};
    my $key = $self->{key};
    my $exists;
    my $time = time();

    $cache->lock();

    if ($exists = $self->exists()) {
        # update last used
        $cache->update_last_use($key, $time);

        # lock entry for reading
        $self->_lock(LOCK_SH);
    }

    $cache->unlock();

    return undef unless $exists;

    File::NFSLock::uncache($self->{path})
        if $cache->cache_lock_level() == Cache::File::LOCK_NFS();

    my $fh = Symbol::gensym();
    my $data;
    my $oldmask = umask $self->{cache}->cache_umask();
    if (open($fh, $self->{path})) {
        binmode $fh;

        # slurp mode
        local $/;
        $data = <$fh>;

        close($fh);
    }
    umask $oldmask;

    # shared locks can be unlocked without holding cache lock
    $self->_unlock();
    return $data;
}

sub size {
    my Cache::File::Entry $self = shift;
    return -s $self->{path};
}

sub remove {
    my Cache::File::Entry $self = shift;

    my $cache = $self->{cache};
    my $key = $self->{key};

    $cache->lock();

    unless (-r $self->{path}) {
        $cache->unlock();
        return;
    }

    my $index = $cache->get_index();
    my $index_entries = $cache->get_index_entries($key)
        or warnings::warnif('Cache', "missing index entry for $key");
    delete $$index{$key};

    if ($$index_entries{age}) {
        my $ageheap = $cache->get_age_heap();
        $ageheap->delete($$index_entries{age}, $key);
    }

    if ($$index_entries{lastuse}) {
        my $useheap = $cache->get_use_heap();
        $useheap->delete($$index_entries{lastuse}, $key);
    }

    if ($$index_entries{expiry}) {
        my $expheap = $cache->get_exp_heap();
        $expheap->delete($$index_entries{expiry}, $key)
    }

    my $size = 0;
    if ($self->_trylock(LOCK_SH)) {
        $size = (-s $self->{path});
        $cache->change_size(-$size);
        $self->_unlock();
    }
    $cache->change_count(-1);

    unlink($self->{path});

    # obliterate any entry lockfile
    unlink($self->{path} . $Cache::File::LOCK_EXT);
    delete $PROCESS_LOCKS{$self->{path}};

    $cache->unlock();

    return $size;
}

sub expiry {
    my Cache::File::Entry $self = shift;
    my $cache = $self->{cache};

    $cache->lock();
    my $index_entries = $cache->get_index_entries($self->{key});
    $cache->unlock();
    return $index_entries? $$index_entries{expiry} : undef;
}

sub _set_expiry {
    my Cache::File::Entry $self = shift;
    my ($time) = @_;

    my $cache = $self->{cache};
    my $key = $self->{key};

    $cache->lock();

    my $index_entries = $cache->get_index_entries($key);

    unless ($index_entries) {
        $cache->unlock();
        croak "Cannot set expiry on non-existant entry: $key";
    }

    my $expheap = $cache->get_exp_heap();
    $expheap->delete($$index_entries{expiry}, $key)
        if $$index_entries{expiry};
    $expheap->add($time, $key) if $time;

    $$index_entries{expiry} = $time;
    $cache->set_index_entries($key, $index_entries);

    $cache->unlock();
}

sub _handle {
    my Cache::File::Entry $self = shift;
    my ($mode, $expiry) = @_;

    # a bit of magic!  Since handles hold a lock indefinitely, and the entry
    # lock code doesn't do recursion (its not necessary) we could get into
    # trouble.  So instead we just ensure that every handle has it's own entry
    # associated with it.
    $self = $self->{cache}->entry($self->{key});

    require Cache::File::Handle;

    my $exists = -e $self->{path};
    my $writing = $mode =~ />|\+/;

    unless ($exists) {
        # return undef unless we're writing a new entry
        $writing or return undef;

        # make the path
        $self->_make_path();
    }

    my $time = time();
    my $cache = $self->{cache};
    my $key = $self->{key};

    # lock indexes
    $cache->lock();

    # grab entry lock
    $self->_lock($writing? LOCK_EX : LOCK_SH);

    # create the attributes if the entry doesn't exist
    unless ($exists) {
        # we're creating the entry
        $cache->create_entry($key, $time);
        $cache->change_count(1);
    }

    # if truncating, reset expiry (or set it creating and its specified)
    $cache->set_expiry($key, $expiry)
        if ($expiry and not $exists) or ($mode =~/\+?>/);
    $cache->update_last_use($key, $time) if $exists;

    my $orig_size = $writing? ($exists? $self->size() : 0) : undef;

    # open handle - entry lock will be held as self persists in the closure
    my $oldmask = umask $cache->cache_umask();
    my $handle = Cache::File::Handle->new($self->{path}, $mode, undef,
        sub { $self->_handle_closed(shift, $orig_size); } );
    umask $oldmask;

    $handle or warnings::warnif('io', 'Failed to open '.$self->{path}.": $!");

    $cache->unlock();

    return $handle;
}


sub validity {
    my Cache::File::Entry $self = shift;

    my $cache = $self->{cache};
    $cache->lock();

    my $index_entries = $cache->get_index_entries($self->{key});

    $cache->unlock();

    return $index_entries? $$index_entries{validity} : undef;
}

sub set_validity {
    my Cache::File::Entry $self = shift;
    my ($data) = @_;

    my $key = $self->{key};
    my $cache = $self->{cache};
    $cache->lock();

    my $index_entries = $cache->get_index_entries($key);

    unless ($index_entries) {
        $self->set('');
    	$index_entries = $cache->get_index_entries($key);
    }

    $$index_entries{validity} = $data;
    $cache->set_index_entries($key, $index_entries);

    $cache->unlock();
}


# UTILITY METHODS

sub _handle_closed {
    my Cache::File::Entry $self = shift;
    my ($handle, $orig_size) = @_;

    unless (defined $orig_size) {
        # shared locks can be unlocked without holding cache lock
        $self->_unlock();
        return;
    }

    my $cache = $self->{cache};

    $cache->lock();

    # check if file still exists and our lock is still valid. this order is
    # used to prevent a race between checking lock and getting size
    my $new_size = $self->size();
    (defined $new_size and $self->_check_lock()) or $new_size = 0;

    # release entry lock
    $self->_unlock();

    # update sizes
    if (defined $orig_size and $orig_size != $new_size) {
        $cache->change_size($new_size - $orig_size);
    }

    $cache->unlock();
}

sub _make_path {
    my Cache::File::Entry $self = shift;

    unless (-d $self->{dir}) {
        my $oldmask = umask $self->{cache}->cache_umask();

        eval { mkpath($self->{dir}); };
        if ($@) {
            warnings::warnif('io',
                    'Failed to create path '.$self->{dir}.": $@");
            return 0;
        }

        umask $oldmask;
    }

    return 1;
}

sub _lock {
    my Cache::File::Entry $self = shift;
    my ($type, $tryonly) = @_;
    $type ||= LOCK_EX;

    # entry already has the lock?
    $self->{lockdetails} and die "entry already holding a lock";

    my $path = $self->{path};
    my $lock_details = $PROCESS_LOCKS{$path};

    if ($lock_details) {
        if ($$lock_details{type} != $type) {
            $tryonly and return 0;
            croak "process already holding entry lock of different type";
        }
        $$lock_details{count}++;
        $self->{lockdetails} = $lock_details;
        return 1;
    }

    # create new entry
    $lock_details = $PROCESS_LOCKS{$path} = {};

    # no need for any locking with LOCK_NONE
    if ($self->{cache}->cache_lock_level() != Cache::File::LOCK_NONE()) {
        local $File::NFSLock::LOCK_EXTENSION = $Cache::File::LOCK_EXT;
        my $oldmask = umask $self->{cache}->cache_umask();

        my $lock = File::NFSLock->new({
                file                => $path,
                lock_type           => $type | ($tryonly? LOCK_NB : 0),
                stale_lock_timeout  => $Cache::File::STALE_LOCK_TIMEOUT,
            });

        unless ($lock) {
            umask $oldmask;
            $tryonly and return 0;
            die "Failed to obtain lock on lockfile on '$path': ".
                $File::NFSLock::errstr."\n";
        }

        # count the number of hard links to the lockfile and open it
        # if we can't reopen the lockfile then it has already been removed...
        # we do the stat on the file rather than the filehandle, as otherwise
        # there would be a race between opening the file and getting the link
        # count (such that we could end up with a link count that is already 0).
        my $fh = Symbol::gensym;
        my $linkcount;
        my $lockfile = $path . $Cache::File::LOCK_EXT;
        if (($linkcount = (stat $lockfile)[3]) and open($fh, $lockfile)) {
            $$lock_details{lock} = $lock;
            $$lock_details{lockfh} = $fh;
            $$lock_details{linkcount} = $linkcount;
        }
        else {
            # lock failed - remove lock details
            delete $PROCESS_LOCKS{$path};
        }
        umask $oldmask;
    }

    # lock obtained

    $$lock_details{type} = $type;
    $$lock_details{count} = 1;

    # use lock details reference as an internal lock check
    $self->{lockdetails} = $lock_details;

    return 1;
}

sub _trylock {
    my Cache::File::Entry $self = shift;
    my ($type) = @_;
    return $self->_lock($type, 1);
}

sub _unlock {
    my Cache::File::Entry $self = shift;

    $self->{lockdetails} or die 'not locked';

    # is our lock still valid?
    $self->_check_lock() or return;

    $self->{lockdetails} = undef;

    my $lock_details = $PROCESS_LOCKS{$self->{path}};
    --$$lock_details{count} == 0
        or return;

    if ($self->{cache}->cache_lock_level() != Cache::File::LOCK_NONE()) {
        $$lock_details{lock}->unlock;
    }
    delete $PROCESS_LOCKS{$self->{path}};
}

# check that we still hold our lock
sub _check_lock {
    my Cache::File::Entry $self = shift;

    $self->{lockdetails} or return 0;
    my $lock_details = $PROCESS_LOCKS{$self->{path}}
        or return 0;

    # check lock details reference still matches global
    $self->{lockdetails} == $lock_details
        or return 0;

    if ($self->{cache}->cache_lock_level() != Cache::File::LOCK_NONE()) {
        # check filehandle is still connected to filesystem
        my $lockfh = $$lock_details{lockfh};
        if (((stat $lockfh)[3] || 0) < $$lock_details{linkcount}) {
            # lock is gone
            delete $PROCESS_LOCKS{$self->{path}};
            return 0;
        }
    }

    return 1;
}


1;
__END__

=head1 SEE ALSO

Cache::Entry, Cache::File

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Entry.pm,v 1.8 2006/01/31 15:23:58 caleishm Exp $

=cut
