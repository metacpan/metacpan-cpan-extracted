=head1 NAME

XAO::Cache - generic interface for caching various data

=head1 SYNOPSIS

 my $cache=XAO::Cache->new(
     retrieve           => &real_retrieve,
     coords             => [qw(outer inner)],
     size               => 100,
     expire             => 30*60,
     backend            => 'Cache::Memory',
 );
 
 my $d1=$cache->get(outer => 123, inner => 'foo');

 my $d2=$cache->get($self, outer => 234, extra => 'bar');

=head1 DESCRIPTION

NOTE: It is almost always better to use Config::cache() method instead
of creating a cache directly with its new() method.  That will also save
on the initialization step - cache object themselves are cached and
reused in that case.

XAO::Cache is a generic cache implementation for caching various "slow"
data such as database content, results of remote requests and so on.

There is no operation of storing data into the cache. Instead cache
is provided with a method to retrieve requested content whenever
required. On subsequent calls a cached value would be returned until
either expiration time is elapsed or cache has overgrown its maximum
size. In which case the real query will be made again to actually
retrieve data.

That means that cache always returns valid data or throws an error if
that is not possible.

To force the cache to use "retrieve" to get a new value that is stored
in the cache give an extra "force_update" parameter to the get() method.

=head1 METHODS

Here is the alphabetically arranged list of methods:

=over

=cut

###############################################################################
package XAO::Cache;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::E::Cache);
use XAO::Objects;

our $VERSION=2.1;

###############################################################################

=item drop ($%)

Removes an element from cache. Useful to make cache aware of changes in
the cached element -- when cached data are no longer valid.

Arguments must contain a list of coordinates the same as in get()
method.

=cut

sub drop ($%) {
    my $self=shift;
    my $backend=$self->{'backend'};
    
    my $object=ref($_[0]) && ref($_[0]) ne 'HASH' ? shift(@_) : undef;
    my $args=get_args(\@_);

    my @c=map { $args->{$_} } @{$self->{'coords'}};
    defined($c[0]) ||
        throw XAO::E::Cache "get - no first coordinate ($args->{coords}->[0])";

    $backend->drop(\@c);
}

###############################################################################

=item drop_all ($)

Remove all elements from the cache.

=cut

sub drop_all ($) {
    my $self=shift;

    if($self->{'backend'}->can('drop_all')) {
        $self->{'backend'}->drop_all();
    }
    else {
        eprint "Cache backend '$self->{'backend'}' does not support drop_all()";
    }
}

###############################################################################

=item get ($%)

Retrieve a data element from the cache. The cache can decide to use real
'retrieve' method to get the data or return previously stored value
instead.

All arguments given to the get() method will be passed to 'retrieve'
method. As a special case if retrieve is a method of some class then a
reference to object of that class must be the first argument followed by
a hash with arguments.

Example of calling 'retrieve' as a function:

 $cache->get(foo => 123, bar => 234);

Example of calling 'retrieve' as a method:

 $cache->get($object, foo => 123, bar => 123);

Example of forcing an update of cache value:

 $cache->get(foo => 123, bar => 234, force_update => 1);

=cut

sub get ($@) {
    my $self=shift;
    my $backend=$self->{'backend'};
    
    my $object=ref($_[0]) && ref($_[0]) ne 'HASH' ? shift(@_) : undef;
    my $args=get_args(\@_);

    my @c=map { $args->{$_} } @{$self->{'coords'}};
    defined($c[0]) ||
        throw XAO::E::Cache "get - no first coordinate ($args->{coords}->[0])";

    # Get method will return undef for non-existent. Or a reference to
    # value (possibly an undef) when a value exists.
    #
    my $data_ref=$args->{'force_update'} ? undef : $backend->get(\@c);

    return $$data_ref if defined $data_ref;

    my $data=&{$self->{'retrieve'}}($object ? ($object) : (),$args);

    $backend->put(\@c => \$data);

    return $data;
}

###############################################################################

=item new (%)

Creates a new independent instance of a cache. When that instance is
destroyed all cache content is destroyed as well. Arguments are:

=over

=item backend

Type of backend that will actuall keep values in cache.
Can be either a XAO object name or an object reference.

Default is 'Cache::Memory' (XAO::DO::Cache::Memory).

=item coords

Coordinates of a data element in the cache -- reference to an array that
keeps names of arguments identifying a data element in the cache. The
order of elements in the list is significant -- first element is
mandatory, the rest is optional.

A combination of all coordinates must uniquely identify a cached data
element among all others in the cache. For instance, if you create a
cache with customers, then 'customer_id' will most probably be your only
coordinate. But if to retrieve a data element you need element type and
id then your coordinates will be:

 coords => ['type', 'id']

There is no default for coordinates.

B<Note>: Coordinates are supposed to be text strings meeting isprint()
criteria.

=item expire

Expiration time for data elements in the cache. Default is no expiration
time.

=item retrieve

Reference to a method or a subroutine that will actually retrieve data
element when there is no element in the cache or cache element has
expired.

The subroutine gets all parameters passed to cache's get() method.

Cache does not perform any checks for correctness of result, so if for
some reason retrieval cannot be performed an error should be thrown
instead of returning undef or other indicator of failure.

=item size

Optional maximum size of the cache in Kbytes. If not specified then only
expiration time will be used as a criteria to throw a data element out
of cache.

=item value_maxlength

Maximum length of an individual value to be stored. Values longer than
this size may be ignored by the cache, but it is still safe to return
then from the retrieve() method. They MAY just not be cached.

Primarily this is useful for memcached configuration to match what the
memcached server is going to reject anyway.

=back

If there is a current project and that project Config object holds a
/cache/config data then that data is used for default values, providing
a way to, for instance, change cache backend globally for all project
caches.

The configuration is structured like this:

    cache => {
        config => {
            common => {
                backend => 'Cache::Memcached',
            },
            foo_cache => {
                backend => 'Cache::Memory',
                size    => 1_000_000,
            },
        },
    },

For a cache named foo_cache the backend would be 'Cache::Memory' and for
all other caches -- 'Cache::Memcached' in that case.

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    # Checking if there is a site configuration and some default
    # parameters in it.
    #
    my $config=$args->{'sitename'}
            ? XAO::Projects::get_project($args->{'sitename'})
            : (XAO::Projects::get_current_project_name() && XAO::Projects::get_current_project());

    if($config && $config->can('get')) {
        $args=merge_refs(
            $config->get('/cache/config/common') || { },
            ($args->{'name'} ? ($config->get('/cache/config/'.$args->{'name'})) : ()),
            $args,
        );
    }

    # Backend -- can be an object reference or an object name
    #
    my $backend=$args->{'backend'} || 'Cache::Memory';
    ### dprint "Created cache '",$args->{'name'},"', backend='$backend'";
    $backend=XAO::Objects->new(objname => $backend) unless ref($backend);

    # Retrieve function must be a code reference
    #
    my $retrieve=$args->{'retrieve'} ||
        throw XAO::E::Cache "new - no 'retrive' argument";
    ref($retrieve) eq 'CODE' ||
        throw XAO::E::Cache "new - 'retrive' must be a code reference";

    # Coords must be an array reference or a single scalar
    #
    my $coords=$args->{'coords'} || $args->{'coordinates'} ||
        throw XAO::E::Cache "new - no 'coords' argument";

    $coords=[ $coords ] if !ref($coords);

    ref($coords) eq 'ARRAY' ||
        throw XAO::E::Cache "new - 'coords' must be an array reference";

    (grep { $_ eq 'force_update' } @$coords) &&
        throw XAO::E::Cache "new - cannot use 'force_update' as a coordinate";

    my $self={
        name        => $args->{'name'},
        backend     => $backend,
        coords      => $coords,
        expire      => $args->{'expire'} || 0,
        retrieve    => $retrieve,
        size        => ($args->{'size'} || 0)*1024,
    };

    # Setting up back-end parameters
    #
    $backend->setup($args);

    # Old caches used to have 'exists' method, which is now obsolete.
    # It requires at least a double key calculation, and in the case of 
    # memcached also a double network trip.
    #
    !$backend->can('exists') ||
        throw XAO::E::Cache "new - backend '$backend' supports an obsolete 'exists' method, upgrade it";

    # Done, blessing
    #
    bless $self,ref($proto) || $proto;
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2013 Andrew Maltsev <am@ejelta.com>.
Copyright (c) 2002 XAO Inc., Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::DO::Cache::Memcached>,
L<XAO::DO::Cache::Memory>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
