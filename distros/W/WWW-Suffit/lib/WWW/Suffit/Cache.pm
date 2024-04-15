package WWW::Suffit::Cache;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Cache - Simple in-memory cache for WWW::Suffit web-servers

=head1 SYNOPSIS

    use WWW::Suffit::Cache;

    my $cache = WWW::Suffit::Cache->new(
        max_keys    => 100,
        expiration  => 60,
    );

    $cache->set(foo => 'bar');
    $cache->set(foo => 'bar', 60);

    my $foo = $cache->get('foo');

=head1 DESCRIPTION

Simple in-memory cache for WWW::Suffit web-servers with size limits and expirations

This module based on L<Mojo::Cache> and L<Cache::Memory::Simple>

=head1 ATTRIBUTES

This class implements the following attributes

=head2 max_keys

    my $max = $cache->max_keys;
    $cache  = $cache->max_keys(100);

Maximum number of cache keys. Setting the value to 0 or undef will disable caching by number of cache keys

=head2 expiration

    my $exp = $cache->expiration;
    $cache  = $cache->expiration(60);

This attribute performs sets or gets the default expiration seconds of live of cache record.
Default is 0 -- disable

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 clean

    $cache = $cache->clean;

Remove all data from cache

=head2 cleanup

    $cache = $cache->cleanup;

Alias for L</clean>

=head2 count

    my $count = $cache->count;

Get actual number of cache records

=head2 del

    $cache = $cache->del('foo');

Alias for L</remove>

=head2 get

    my $value = $cache->get('foo');

Get cached value

=head2 purge

    $cache = $cache->purge;

Purge expired data

This module does not purge expired data automatically. You need to call this method if you need

=head2 remove

    $cache = $cache->remove('foo');

Delete key from cache

=head2 rm

    $cache = $cache->rm('foo');

Alias for L</remove>

=head2 set

    $cache = $cache->set(foo => 'bar');
    $cache = $cache->set(foo => 'bar', 60);

Set cached value with/without expiration time

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Cache>, L<Cache::Memory::Simple>, L<Cache::Redis>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Mojo::Base -base;

has 'max_keys' => 0;
has 'expiration' => 0;

sub get {
    my $self = shift;
    my $key = shift;
    my $rec = ($self->{cache} // {})->{$key};
    return undef unless defined $rec; # Skip if undefined
    my $exp = $rec->[0];
    my $val = $rec->[1];
    my $max = $self->max_keys || 0;
       $max = 0 if $max < 0;
    return $val unless $exp; # If no exp found then need just to return value
    return $val if $exp > time; # Return value if not expired
    delete $self->{cache}->{$key}; # Remove expired data from cache
    $self->_dequeue($key) if $max; # Remove from queue
    return undef;
}
sub set {
    my $self = shift;
    my $key = shift;
    my $val = shift;
    my $exp = shift // $self->expiration;
    my $max = $self->max_keys || 0;
       $max = 0 if $max < 0;
    my $cache = $self->{cache} //= {};
    my $queue = $self->{queue} //= [];
    if ($max) {
        delete $cache->{shift @$queue} while @$queue >= $max; # Remove first cache-records
        push @$queue, $key unless exists $cache->{$key}; # Add key of cache-record to queue (enqueue) if it yet not exists
    }
    $cache->{$key} = [$exp ? ($exp + time) : undef, $val]; # Sets the new or updates the existed cache-record
    return $self;
}
sub remove {
    my $self = shift;
    my $key = shift;
    my $cache = $self->{cache} //= {};
    delete $cache->{$key};
    my $max = $self->max_keys || 0;
       $max = 0 if $max < 0;
    $self->_dequeue($key) if $max; # Remove from queue
    return $self;
}
sub rm { goto &remove } # alias
sub del { goto &remove } # alias
sub count {
    my $self = shift;
    return 1 * keys %{$self->{cache}};
}
sub purge {
    my $self = shift;
    my $cache = $self->{cache} //= {};
    my $max = $self->max_keys || 0;
       $max = 0 if $max < 0;
    for my $key (keys %$cache) {
        my $exp = $cache->{$key}->[0];
        if ($exp && $exp < time ) {
            delete $cache->{$key};
            $self->_dequeue($key) if $max; # Remove from queue
        }
    }
    return $self;
}
sub clean {
    my $self = shift;
       $self->{cache} = {};
       $self->{queue} = [];
    return $self;
}
sub cleanup { goto &clean } # alias

sub _dequeue {
    my $self = shift;
    my $key = shift;
    return $self unless defined $key;
    my $queue = $self->{queue} //= [];
    my $pointer = 0;
    foreach my $pointer (0 .. scalar(@$queue)-1) {
        if ($queue->[$pointer] eq $key) {
            splice(@$queue, $pointer, 1);
            last;
        }
    }
    return $self;
}

1;

__END__
