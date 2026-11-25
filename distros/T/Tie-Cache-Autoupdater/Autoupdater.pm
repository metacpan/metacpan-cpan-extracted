package Tie::Cache::Autoupdater;

use strict;
use warnings;

use Storable 'dclone';

# _now() is the clock timeouts are measured on, best first:
#   - the monotonic clock: NTP corrections or a manual change of the system
#     time cannot move it, so a clock set back cannot freeze a cached value;
#   - Time::HiRes::time, for fractional timeouts without a monotonic clock;
#   - the built-in time, in whole seconds.
# The monotonic clock counts from an arbitrary point (usually boot), so its
# readings mean nothing on their own - which is why a fresh key has
# last => undef rather than 0.
BEGIN {
    my $hires = eval { require Time::HiRes; 1 };

    my $monotonic;
    $monotonic = eval {
        my $id = Time::HiRes::CLOCK_MONOTONIC();
        Time::HiRes::clock_gettime($id) >= 0 ? $id : undef     # -1 on failure
    } if $hires;

    *_now = defined $monotonic ? sub { Time::HiRes::clock_gettime($monotonic) }
          : $hires             ? \&Time::HiRes::time
          :                      sub { time };
}

our $VERSION = '0.23';

sub TIEHASH {
    my $class       = shift;
    my %structure   = @_;

    my $self = {};
    while ( my ($k, $v) = each %structure ) {
        $self->{ $k } = {
            timeout => $v->{timeout} || 1,
            source  => $v->{source},
            last    => undef,
            result  => undef,
            clone   => $v->{clone} ? 1 : 0
        }
    }

    bless $self, $class;
}

sub FETCH {
    my ( $self, $k ) = @_;

    return undef unless exists $self->{ $k };
    _fetch( $_[0], $k )
}

sub STORE {
    my ( $self, $k, $v ) = @_;
    $self->{ $k } = {
        timeout => $v->{timeout} || 1,
        source  => $v->{source},
        last    => undef,
        result  => undef,
        clone   => $v->{clone} ? 1 : 0
    }
}

sub FIRSTKEY {
    keys %{$_[0]};
    scalar each %{$_[0]}
}

sub NEXTKEY  { scalar each %{$_[0]} }

sub EXISTS   { exists $_[0]->{ $_[1] } }
sub DELETE   { delete $_[0]->{ $_[1] } }
sub CLEAR    { %{ $_[0] } = () }
sub SCALAR   { scalar %{ $_[0] } }
sub UNTIE    { $_[0] = undef }
sub DESTROY  { return 1 }

sub _fetch {
    my ( $self, $k ) = @_;

    if ( !defined $self->{$k}{last}
        || $self->{$k}{last} + $self->{$k}{timeout} < _now() ) {

        # Failure is judged by eval's own value, not by $@: before 5.14 a
        # destructor that runs eval while the source is dying clears $@, and an
        # exception object may be false - either way the error would be taken
        # for an empty result and cached for the whole timeout.
        my @result;
        my $ok = eval {
            # Before 5.18, calling an undefined source warns "Use of
            # uninitialized value in subroutine entry" on top of dying.
            no warnings 'uninitialized';
            @result = $self->{$k}{source}->();
            1
        };
        unless ( $ok ) {
            my $error = "$@";
            $error = 'unknown error' unless length $error;
            warn qq/Check source subroutine for key $k. Error - $error\n/;
            return undef
        }

        if ( @result == 1 ) {
            $self->{$k}{result} = $result[0];
        } elsif ( !@result ) {
            $self->{$k}{result} = undef;
        } else {
            $self->{$k}{result} = \@result;
        }

        $self->{$k}{last} = _now();
    }

    return $self->{$k}{clone} && ref $self->{$k}{result}
        ? dclone($self->{$k}{result})
        : $self->{$k}{result};
}

1;

__END__

=head1 NAME

Tie::Cache::Autoupdater - a tied hash whose values refresh themselves on a timeout

=head1 VERSION

This documentation refers to C<Tie::Cache::Autoupdater> version 0.23

=head1 SYNOPSIS

    use Tie::Cache::Autoupdater;

    tie my %cache, 'Tie::Cache::Autoupdater',
        settings => { source => \&read_settings_from_db, timeout => 60 },
        counters => { source => \&count_table_rows,      timeout => 10 };

    # Every read returns the cached value, or calls the source subroutine
    # again and caches the new result if the timeout has expired.
    my $settings = $cache{settings};
    my $counters = $cache{counters};

    # Keys can also be registered after the hash has been tied.
    $cache{file_count} = {
        source  => sub { scalar glob "$path/*" },
        timeout => 2.5,                 # fractional timeouts need Time::HiRes
    };

    # Ask for a deep copy if the caller is going to modify the data.
    $cache{report} = {
        source  => \&build_report,
        timeout => 30,
        clone   => 1,
    };

=head1 DESCRIPTION

Long-running processes - FastCGI workers, daemons, queue consumers - often need
data that changes rarely, but not never: site settings, row counters, a price
list, a feature flag. Fetching it from the database on every request is
wasteful, and fetching it once at start-up is wrong: the process may stay alive
for days or weeks, while the data behind it changes every few minutes.

This module ties a hash to a set of named data sources. You register a key with
a subroutine and a timeout, and from then on reading that key gives you the
cached value until the timeout expires. The first read after expiry calls the
subroutine again, and its result becomes the new cached value.

The refresh is lazy: it happens inside the read itself. There is no timer, no
background process and no extra thread, so a key that nobody reads is never
refreshed, and the source subroutine is called at most once per timeout no
matter how many times the key is read.

=head2 Registering keys

A key can be registered when the hash is tied:

    tie my %cache, 'Tie::Cache::Autoupdater', db_query => {
        timeout => 10,
        source  => sub {
            my $sth = $DBH->prepare('select * from table');
            $sth->execute;
            return $sth->fetchall_arrayref;
        }
    };

or at any time afterwards, by assigning to it:

    $cache{db_query} = {
        timeout => 10,
        source  => sub {
            my $sth = $DBH->prepare('select * from table');
            $sth->execute;
            return $sth->fetchall_arrayref;
        }
    };

Both forms are equivalent, and there is no limit on the number of keys. Note
that an assignment does not store a value - it describes where the value comes
from. Assigning to a key that is already registered replaces its description
and discards whatever was cached for it, so the next read calls the new source
immediately.

=head2 Parameters

Each key is described by a hash reference with the following fields.

=head3 source

A reference to the subroutine that produces the value. It is called with no
arguments, in list context. Required: a key registered without it produces a
warning and C<undef> on the first read.

=head3 timeout

How long a cached value stays fresh, in seconds. Defaults to 1 second. With
C<Time::HiRes> installed the timeout may be fractional; without it, values
below 1 second simply mean "refresh on every read whose timestamp differs".

Where the system provides a monotonic clock (Linux, the BSDs, macOS and most
other Unix systems, through C<Time::HiRes>), timeouts are measured on it, so
setting the system clock back - by hand or by an NTP correction - does not keep
a stale value in the cache, and setting it forward does not expire values early.
Without one, the wall clock is used.

In the example below the value of C<db_counters> is refreshed at most once
every 0.2 seconds, and the value of C<file_count> at most once every
2.5 seconds:

    tie %cache, 'Tie::Cache::Autoupdater',
        db_counters => {
            timeout => 0.2,
            source  => sub {
                my $sth = $DBH->prepare('select count(*) from table2');
                $sth->execute;
                return ($sth->fetchrow_array);
            }
        },
        file_count => {
            timeout => 2.5,
            source  => sub { return scalar glob "$path/*" }
        };

A false timeout (C<0>, C<undef>, an empty string) is replaced by the default of
1 second rather than meaning "never cache".

=head3 clone

Whether to return a deep copy of the cached data instead of the cached data
itself. Off by default. See L</"Sharing and cloning"> below.

=head2 What gets cached

The source subroutine is called in list context, and what it returns is
normalised before being stored:

=over 4

=item *

a single value is cached as it is, whether it is a plain scalar or a reference;

=item *

two or more values are cached as a reference to an array holding them;

=item *

an empty list is cached as C<undef>.

=back

So a source that ends with C<return ($count, $sum)> yields an array reference,
while a source that ends with C<return $hashref> yields that same hash
reference. If you want a structure back, return a reference to it explicitly -
returning a plain list of key/value pairs gives you an array reference, not a
hash.

=head2 Sharing and cloning

By default the cached value is returned as it is. For a reference this means
every caller receives the very reference that the cache holds, so modifying the
returned data silently modifies the cache, and every later read sees the change
until the timeout expires.

Set C<clone> to a true value to get a fresh deep copy on every read:

    $cache{settings} = {
        source  => \&read_settings_from_db,
        timeout => 60,
        clone   => 1,
    };

    my $settings = $cache{settings};
    $settings->{theme} = 'dark';        # affects this copy only

Cloning is done with C<Storable::dclone> and applies to references only; plain
scalars are returned unchanged, with or without the flag. Because the copy is
made on every single read, leave C<clone> off when callers treat the data as
read-only - it is the cheaper and the common case.

C<dclone> cannot copy code references, globs, file handles or C<Storable>-hostile
objects, and will die on them. A source returning such data has to be used
without C<clone>.

=head2 Error handling

The source subroutine is called inside C<eval>. If it dies, the module emits a
warning naming the key and the error:

    Check source subroutine for key db_query. Error - DBI connect failed ...

the read returns C<undef>, and the timestamp of the key is left untouched, so
the next read retries immediately instead of waiting for the timeout. A value
cached by an earlier successful call stays in the cache but is not returned by
the failed read; it will be returned again only if a later call succeeds.

Every C<die> counts as a failure, including one whose error is lost or empty -
a destructor that clears C<$@> on perl older than 5.14, or an exception object
that is false. The warning then says C<unknown error>.

Reading a key that was never registered returns C<undef> quietly, without
calling anything and without a warning.

=head2 Standard hash operations

The tied hash supports the usual operations, with the cache in mind:

=over 4

=item C<exists $cache{key}>

True if the key is registered. It never calls the source subroutine and says
nothing about whether a value is currently cached.

=item C<delete $cache{key}>

Unregisters the key and throws away its cached value.

=item C<keys %cache>, C<each %cache>

C<keys> lists the registered keys. C<each> returns a key and its value, and the
value goes through a normal read - so iterating may call source subroutines and
refresh expired keys.

=item C<%cache = ()>

Unregisters every key.

=item C<untie %cache>

Stops the tie; the cached data is released with the underlying object.

=back

=head1 DEPENDENCIES

Perl 5.8 or newer.

=over 4

=item *

L<Storable> - core module, used for C<clone>.

=item *

L<Time::HiRes> - core module, optional. Loaded at compile time if available,
and then used for its monotonic clock, or failing that for its C<time>, so
that fractional timeouts work and timeouts are immune to system clock changes.

=back

=head1 CAVEATS

The cache lives in the memory of one process. Under a pre-forking server each
worker keeps its own independent copy, with its own timestamps, so different
workers may hold different values for the same key at the same moment. The
module performs no locking and does nothing to coordinate workers; if you need
a cache shared between processes, this is not it.

Because the refresh is driven by reads, the age of a value is bounded by the
timeout only for keys that are read regularly. A key read once an hour with a
timeout of 10 seconds is refreshed once an hour, not every 10 seconds.

=head1 AUTHOR

Anton Morozov (antonfin@cpan.org)

=head1 DEVELOPMENT

=head2 Repository

http://github.com/antonfin/Tie-Cache-Autoupdater

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2026 by Anton Morozov (antonfin@cpan.org).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See the F<LICENSE> file in the distribution for the full text.

=cut
