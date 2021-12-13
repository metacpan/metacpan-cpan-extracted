=head1 NAME

Cache - the Cache interface

=head1 DESCRIPTION

The Cache modules are designed to assist a developer in persisting data for a
specified period of time.  Often these modules are used in web applications to
store data locally to save repeated and redundant expensive calls to remote
machines or databases.

The Cache interface is implemented by derived classes that store cached data
in different manners (such as files on a filesystem, or in memory).

=head1 USAGE

To use the Cache system, a cache implementation must be chosen to suit your
needs.  The most common is Cache::File, which is suitable for sharing data
between multiple invocations and even between concurrent processes.

Using a cache is simple.  Here is some very simple sample code for
instantiating and using a file system based cache.

  use Cache::File;

  my $cache = Cache::File->new( cache_root => '/tmp/cacheroot' );
  my $customer = $cache->get( $name );

  unless ($customer) {
      $customer = get_customer_from_db( $name );
      $cache->set( $name, $customer, '10 minutes' );
  }

  return $customer;

Of course, far more powerful methods are available for accessing cached data.
Also see the TIE INTERFACE below.

=head1 METHODS

=over

=cut
package Cache;

require 5.006;
use strict;
use warnings;
use Carp;
use Date::Parse;

# For registering the 'Cache' category. See:
# https://rt.cpan.org/Public/Bug/Display.html?id=95608
use warnings::register;

use base qw(Tie::Hash);
use fields qw(
        default_expires removal_strategy size_limit
        load_callback validate_callback);

our $VERSION = '2.11';

our $EXPIRES_NOW = 'now';
our $EXPIRES_NEVER = 'never';

# map of expiration formats to their respective time in seconds
my %_Expiration_Units = ( map(($_,             1), qw(s second seconds sec)),
                          map(($_,            60), qw(m minute minutes min)),
                          map(($_,         60*60), qw(h hour hours)),
                          map(($_,      60*60*24), qw(d day days)),
                          map(($_,    60*60*24*7), qw(w week weeks)),
                          map(($_,   60*60*24*30), qw(M month months)),
                          map(($_,  60*60*24*365), qw(y year years)) );


sub new {
    my Cache $self = shift;
    my $args = $#_? { @_ } : shift;

    ref $self or croak 'Must use a subclass of Cache';

    $self->set_default_expires($args->{default_expires});

        # set removal strategy
    my $strategy = $args->{removal_strategy} || 'Cache::RemovalStrategy::LRU';
    unless (ref($strategy)) {
        eval "require $strategy" or die @_;
        $strategy = $strategy->new();
    }
    $self->{removal_strategy} = $strategy;

    # set size limit
    $self->{size_limit} = $args->{size_limit};

    # set load callback
    $self->set_load_callback($args->{load_callback});

    # set load callback
    $self->set_validate_callback($args->{validate_callback});

    return $self;
}

=item my $cache_entry = $c->entry( $key )

Return a 'Cache::Entry' object for the given key.  This object can then be
used to manipulate the cache entry in various ways.  The key can be any scalar
string that will uniquely identify an entry in the cache.

=cut

sub entry;

=item $c->purge()

Remove all expired data from the cache.

=cut

sub purge;

=item $c->clear()

Remove all entries from the cache - regardless of their expiry time.

=cut

sub clear;

=item my $num = $c->count()

Returns the number of entries in the cache.

=cut

sub count;

=item my $size = $c->size()

Returns the size (in bytes) of the cache.

=cut

# if an argument is provided, then the target is the 'shortcut' method set($key)
sub size {
    my Cache $self = shift;
    return @_? $self->entry_size(@_) : $self->cache_size();
}

# implement this method instead
sub cache_size;


=back

=head1 PROPERTIES

When a cache is constructed these properties can be supplied as options to the
new() method.

=over

=item default_expires

The current default expiry time for new entries into the cache.  This property
can also be reset at any time.

 my $time = $c->default_expires();
 $c->set_default_expires( $expiry );

=cut

sub default_expires {
    my Cache $self = shift;
    return Canonicalize_Expiration_Time($self->{default_expires});
}

sub set_default_expires {
    my Cache $self = shift;
    my ($time) = @_;
    # This could be made more efficient by converting to unix time here,
    # except that special handling would be required for relative times.
    # For now default_expires() does all the conversion.
    $self->{default_expires} = $time;
}

=item removal_strategy

The removal strategy object for the cache.  This is used to remove
object from the cache in order to maintain the cache size limit.

When setting the removal strategy in new(), the name of a strategy package or
a blessed strategy object reference should be provided  (in the former case an
object is constructed by calling the new() method of the named package).

The strategies 'Cache::RemovalStrategy::LRU' and
'Cache::RemovalStrategy::FIFO' are available by default.

 my $strategy = $c->removal_strategy();

=cut

sub removal_strategy {
    my Cache $self = shift;
    return $self->{removal_strategy};
}

=item size_limit

The size limit for the cache.

 my $limit = $c->size_limit();

=cut

sub size_limit {
    my Cache $self = shift;
    return $self->{size_limit};
}

=item load_callback

The load callback for the cache.  This may be set to a function that will get
called anytime a 'get' is issued for data that does not exist in the cache.

 my $limit = $c->load_callback();
 $c->set_load_callback($callback_func);

=cut

sub load_callback {
    my Cache $self = shift;
    return $self->{load_callback};
}

sub set_load_callback {
    my Cache $self = shift;
    my ($load_callback) = @_;
    $self->{load_callback} = $load_callback;
}

=item validate_callback

The validate callback for the cache.  This may be set to a function that will
get called anytime a 'get' is issued for data that does not exist in the
cache.

 my $limit = $c->validate_callback();
 $c->set_validate_callback($callback_func);

=cut

sub validate_callback {
    my Cache $self = shift;
    return $self->{validate_callback};
}

sub set_validate_callback {
    my Cache $self = shift;
    my ($validate_callback) = @_;
    $self->{validate_callback} = $validate_callback;
}


=back

=head1 SHORTCUT METHODS

These methods all have counterparts in the Cache::Entry package, but are
provided here as shortcuts.  They all default to just wrappers that do
'$c->entry($key)->method_name()'.  For documentation, please refer to
Cache::Entry.

=over

=item my $bool = $c->exists( $key )

=cut

sub exists {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->exists();
}

=item $c->set( $key, $data, [ $expiry ] )

=cut

sub set {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->set(@_);
}

=item my $data = $c->get( $key )

=cut

sub get {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->get();
}

=item my $data = $c->size( $key )

=cut

# method is called 'entry_size' as the size() method is also a normal Cache
# method for returning the size of the entire cache.  It calls this instead if
# given an argument.
sub entry_size {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->size();
}

=item $c->remove( $key )

=cut

sub remove {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->remove();
}

=item $c->expiry( $key )

=cut

sub expiry {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->expiry();
}
sub get_expiry { shift->expiry(@_); }

=item $c->set_expiry( $key, $time )

=cut

sub set_expiry {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->set_expiry(@_);
}

=item $c->handle( $key, [$mode, [$expiry] ] )

=cut

sub handle {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->handle();
}

=item $c->validity( $key )

=cut

sub validity {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->validity();
}
sub get_validity { shift->validity(@_); }

=item $c->set_validity( $key, $data )

=cut

sub set_validity {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->set_validity(@_);
}

=item $c->freeze( $key, $data, [ $expiry ] )

=cut

sub freeze {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->freeze(@_);
}

=item $c->thaw( $key )

=cut

sub thaw {
    my Cache $self = shift;
    my $key = shift;
    return $self->entry($key)->thaw();
}


=back

=head1 TIE INTERFACE

  tie %hash, 'Cache::File', { cache_root => $tempdir };

  $hash{'key'} = 'some data';
  $data = $hash{'key'};

The Cache classes can be used via the tie interface, as shown in the synopsis.
This allows the cache to be accessed via a hash.  All the standard methods
for accessing the hash are supported , with the exception of the 'keys' or
'each' call.

The tie interface is especially useful with the load_callback to automatically
populate the hash.

=head1 REMOVAL STRATEGY METHODS

These methods are only for use internally (by concrete Cache implementations).

These methods define the interface by which the removal strategy object can
manipulate the cache (the Cache is the 'context' of the strategy).  By
default, methods need to be provided to remove the oldest or stalest objects
in the cache - thus allowing support for the default FIFO and LRU removal
strategies.  All derived Cache implementations should support these methods
and may also introduce additional methods (and additional removal strategies
to match).

=over

=item my $size = $c->remove_oldest()

Removes the oldest entry in the cache and returns its size.

=cut

sub remove_oldest;

=item my $size = $c->remove_stalest()

Removes the 'stalest' (least used) object in the cache and returns its
size.

=cut

sub stalest;

=item $c->check_size( $size )

This method isn't actually part of the strategy interface, nor does it need
to be defined by Cache implementations.  Instead it should be called by
implementations whenever the size of the cache increases.  It will take care
of checking the size limit and invoking the removal strategy if required.  The
size argument should be the new size of the cache.

=cut

sub check_size {
    my Cache $self = shift;
    my ($size) = @_;

    defined $self->{size_limit} or return;

    if ($size > $self->{size_limit}) {
        $self->{removal_strategy}->remove_size(
                $self, $size - $self->{size_limit});
    }
}


=back

=head1 UTILITY METHODS

These methods are only for use internally (by concrete Cache implementations).

=over

=item my $time = Cache::Canonicalize_Expiration_Time($timespec)

Converts a timespec as described for Cache::Entry::set_expiry() into a unix
time.

=back

=cut

sub Canonicalize_Expiration_Time {
    my $timespec;

    my $timespec_param = shift(@_);
    if (! $timespec_param)
    {
        return undef;
    }
    $timespec = lc($timespec_param);

    my $time;

    if ($timespec =~ /^\s*\d+\s*$/) {
        $time = $timespec;
    }
    elsif ($timespec eq $EXPIRES_NOW) {
        $time = 0;
    }
    elsif ($timespec eq $EXPIRES_NEVER) {
        $time = undef;
    }
    elsif ($timespec =~ /^\s*-/) {
        # negative time?
        $time = 0;
    }
    elsif ($timespec =~ /^\s*\+(\d+)\s*$/) {
        $time = $1 + time();
    }
    elsif ($timespec =~ /^\s*(\+?\d+)\s*(\w*)\s*$/
        and exists($_Expiration_Units{$2}))
    {
        $time = $_Expiration_Units{$2} * $1 + time();
    }
    else {
        $time = str2time($timespec)
            or croak "invalid expiration time '$timespec'";
    }

    return $time;
}


# Hash tie methods

sub TIEHASH {
    my Cache $class = shift;
    return $class->new(@_);
}

sub STORE {
    my Cache $self = shift;
    my ($key, $value) = @_;
    return $self->set($key, $value);
}

sub FETCH {
    my Cache $self = shift;
    my ($key) = @_;
    return $self->get($key);
}

# NOT SUPPORTED
sub FIRSTKEY {
    my Cache $self = shift;
    return undef;
}

# NOT SUPPORTED
sub NEXTKEY {
    my Cache $self = shift;
    #my ($lastkey) = @_;
    return undef;
}

sub EXISTS {
    my Cache $self = shift;
    my ($key) = @_;
    return $self->exists($key);
}

sub DELETE {
    my Cache $self = shift;
    my ($key) = @_;
    return $self->remove($key);
}

sub CLEAR {
    my Cache $self = shift;
    return $self->clear();
}


1;
__END__

=head1 SEE ALSO

Cache::Entry, Cache::File, Cache::RemovalStrategy

=head1 DIFFERENCES FROM CACHE::CACHE

The Cache modules are a total redesign and reimplementation of Cache::Cache
and thus not directly compatible.  It would be, however, quite possible to
write a wrapper module that provides an identical interface to Cache::Cache.

The semantics of use are very similar to Cache::Cache, with the following
exceptions:

=over

=item The get/set methods DO NOT serialize complex data types.  Use
freeze/thaw instead (but read the notes in Cache::Entry).

=item The get_object / set_object methods are not available, but have been
superseded by the more flexible entry method and Cache::Entry class.

=item There is no concept of 'namespace' in the basic cache interface,
although implementations (eg. Cache::Memory) may choose to provide them.  For
instance, File::Cache does not provide this - but different namespaces can be
created by varying cache_root.

=item In the current Cache implementations purging is done automatically -
there is no need to explicitly enable auto purge on get/set.  The purging
algorithm is no longer implemented in the base Cache class, but is left up to
the implementations and may thus be implemented in the most efficient way for
the storage medium.

=item Cache::SharedMemory is not yet available.

=item Cache::File no longer supports separate masks for entries and
directories.  It is not a very secure configuration and presents numerous
issues for cache consistency and is hence deprecated.  There is still some
work to be done to ensure cache consistency between accesses by different
users.

=back

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Cache.pm,v 1.7 2006/01/31 15:23:58 caleishm Exp $

=cut
