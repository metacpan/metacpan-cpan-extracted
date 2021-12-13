=head1 NAME

Cache::Entry - interface for a cache entry

=head1 SYNOPSIS

  my Cache::Entry $entry = $cache->entry( $key )
  my $data;
  if ($entry->exists()) {
      $data = $entry->get();
  }
  else {
      $data = get_some_data($key);
      $entry->set($data, '10 minutes');
  }

=head1 DESCRIPTION

Objects derived from Cache::Entry represent an entry in a Cache.  Methods are
provided that act upon the data in the entry, and allow you to set things like
the expiry time.

Users should not create instances of Cache::Entry directly, but instead use
the entry($key) method of a Cache instance.

=head1 METHODS

=over

=cut
package Cache::Entry;

require 5.006;
use strict;
use warnings;
use Cache;
use Storable;
use Carp;

use fields qw(cache key);

our $VERSION = '2.11';


sub new {
    my Cache::Entry $self = shift;
    my ($cache, $key) = @_;

    ref $self or croak 'Must use a subclass of Cache::Entry';

    $self->{cache} = $cache;
    $self->{key} = $key;

    return $self;
}

=item my $cache = $e->cache()

Returns a reference to the cache object this entry is from.

=cut

sub cache {
    my Cache::Entry $self = shift;
    return $self->{cache};
}

=item my $key = $e->key()

Returns the cache key this entry is associated with.

=cut

sub key {
    my Cache::Entry $self = shift;
    return $self->{key};
}

=item my $bool = $e->exists()

Returns a boolean value (1 or 0) to indicate whether there is any data
present in the cache for this entry.

=cut

sub exists;

=item $e->set( $data, [ $expiry ] )

Stores the data into the cache.  The data must be a scalar (if you want to
store more complex data types, see freeze and thaw below).

The expiry time may be provided as an optional 2nd argument and is in the same
form as for 'set_expiry($time)'.

=cut

# ensure expiry is normalized then call _set
sub set {
    my Cache::Entry $self = shift;
    my ($data, $expiry) = @_;

    unless (defined $data) {
        return $self->remove();
    }

    ref($data) and warnings::warnif('Cache','Reference passed to set');

    if ($#_ < 1) {
        $expiry = $self->{cache}->default_expires();
    }
    else {
        $expiry = Cache::Canonicalize_Expiration_Time($expiry);
    }

    if (defined $expiry and $expiry == 0) {
        return $self->remove();
    }

    return $self->_set($data, $expiry);
}

# Implement this method instead of set
sub _set;

=item my $data = $e->get()

Returns the data from the cache, or undef if the entry doesn't exist.

=cut

# ensure load_callback and validity callback is issued
sub get {
    my Cache::Entry $self = shift;
    my Cache $cache = $self->{cache};

    my $result = $self->_get(@_);

    if (defined $result) {
        my $validate_callback = $cache->{validate_callback};
        $validate_callback or return $result;
        $validate_callback->($self) and return $result;
    }

    my $load_callback = $cache->{load_callback}
        or return undef;
    my @options;
    ($result, @options) = $load_callback->($self);
    $self->set($result, @options) if defined $result;

    return $result;
}

# Implement this method instead of get
sub _get;

=item my $size = $e->size()

Returns the size of the entry data, or undef if the entry doesn't exist.

=cut

sub size;

=item $e->remove()

Clear the data for this entry from the cache.

=cut

sub remove;

=item my $expiry = $e->expiry()

Returns the expiry time of the entry, in seconds since the epoch.

=cut

sub expiry;
sub get_expiry { shift->expiry(@_); }

=item $e->set_expiry( $time )

Set the expiry time in seconds since the epoch, or alternatively using a
string like '10 minutes'.  Valid units are s, second, seconds, sec, m, minute,
minutes, min, h, hour, hours, w, week, weeks, M, month, months, y, year and
years.  You can also specify an absolute time, such as '16 Nov 94 22:28:20' or
any other time that Date::Parse can understand.  Finally, the strings 'now'
and 'never' may also be used.

=cut

# ensure time is normalized then call _set_expiry
sub set_expiry {
    my Cache::Entry $self = shift;
    my ($time) = @_;

    my $expiry = Cache::Canonicalize_Expiration_Time($time);

    if (defined $expiry and $expiry == 0) {
        return $self->remove();
    }

    $self->_set_expiry($expiry);
}

# Implement this method instead of set_expiry
sub _set_expiry;

=item my $fh = $e->handle( [$mode, [$expiry] ] )

Returns an IO::Handle by which data can be read, or written, to the cache.
This is useful if you are caching a large amount of data - although it should
be noted that only some cache implementations (such as Cache::File) provide an
efficient mechanism for implementing this.

The optional mode argument can be any of the perl mode strings as used for the
open function '<', '+<', '>', '+>', '>>' and '+>>'.  Alternatively it can be
the corresponding fopen(3) modes of 'r', 'r+', 'w', 'w+', 'a' and 'a+'.  The
default mode is '+<' (or 'r+') indicating reading and writing.

The second argument is used to set the expiry time for the entry if it doesn't
exist already and the handle is opened for writing.  It is also used to reset
the expiry time if the entry is truncated by opening in the '>' or '+>' modes.
If the expiry is not provided in these situations then the default expiry time
for the cache is applied.

Cache implementations will typically provide locking around cache entries, so
that writers will have have an exclusive lock and readers a shared one.  Thus
the method get() (or obtaining another handle) should be avoided whilst a
write handle is held.  Using set() or remove(), however, should be supported.
These clear the current entry and whilst they do not invalidate open handles,
those handle will from then on refer to old data and any changes to the data
will be discarded.

=cut

# ensure mode and expiry are normalized then call _handle
sub handle {
    my Cache::Entry $self = shift;
    my ($mode, $expiry) = @_;

    # normalize mode
    if ($mode) {
        require IO::Handle;
        $mode = IO::Handle::_open_mode_string($mode);
    }
    else {
        $mode = '+<';
    }

    if ($#_ < 1) {
        $self->_handle($mode, $self->{cache}->default_expires());
    }
    else {
        $self->_handle($mode, Cache::Canonicalize_Expiration_Time($expiry));
    }
}

# Implement this method instead of handle
sub _handle;


=back

=head1 STORING VALIDITY OBJECTS

There are two additional set & get methods that can be used to store a
validity object that is associated with the data in question.  Typically this
is useful in conjunction with a validate_callback, and may be used to store a
timestamp or similar to validate against.  The validity data stored may be any
complex data that can be serialized via Storable.

=over

=item $e->validity()

=cut

sub validity;
sub get_validity { shift->validity(@_); }

=item $e->set_validity( $data )

=cut

sub set_validity;


=back

=head1 STORING COMPLEX OBJECTS

The set and get methods only allow for working with simple scalar types, but
if you want to store more complex types they need to be serialized first.  To
assist with this, the freeze and thaw methods are provided.  They are simple
wrappers to get & set that use Storable to do the serialization and
de-serialization of the data.

Note, however, that you must be careful to ONLY use 'thaw' on data that was
stored via 'freeze'.  Otherwise the stored data wont actually be in Storable
format and it will complain loudly.

=over

=item $e->freeze( $data, [ $expiry ] )

Identical to 'set', except that data may be any complex data type that can be
serialized via Storable.

=cut

sub freeze {
    my Cache::Entry $self = shift;
    my ($data, @args) = @_;
    ref($data) or warnings::warnif('Cache','Non-reference passed to freeze');
    return $self->set(Storable::nfreeze($data), @args);
}

=item $e->thaw()

Identical to 'get', except that it will return a complex data type that was
set via 'freeze'.

=cut

sub thaw {
    my Cache::Entry $self = shift;
    my $data = $self->get(@_);
    defined $data or return undef;
    return Storable::thaw($data);
}

=back

=cut


1;
__END__

=head1 SEE ALSO

Cache, Cache::File

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
