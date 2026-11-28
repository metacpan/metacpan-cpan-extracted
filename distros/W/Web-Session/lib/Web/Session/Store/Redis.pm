package Web::Session::Store::Redis;

use strict;

our $VERSION = '1.0.0';

our $redis;
our %reused_connections;

BEGIN {
    $redis = 'Redis::Fast';
    eval 'use Redis::Fast';
    if ($@) {
        require Redis;
        $redis = 'Redis';
    }
}

# Redis clients croak on characters above U+00FF: key names built from a field
# name or a value are sent as Latin-1 bytes (existing index sets keep their
# name) or, if they hold such characters, as UTF-8 bytes
sub keyName {
    my $name = shift;
    $name = "$name";
    utf8::encode($name) unless ( utf8::downgrade( $name, 1 ) );
    return $name;
}

sub new {
    my ( $class, $session ) = @_;
    my $self;

    $self->{cache} = $class->_getRedis( $session->{args} );

    bless $self, $class;
}

sub insert {
    my ( $self, $session ) = @_;
    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    my $id  = $session->{data}->{_session_id};
    my $ttl = $session->{args}->{TTL};
    if ($ttl) {
        $self->{cache}->set( $id, $session->{serialized}, 'EX', $ttl );
    }
    else {
        $self->{cache}->set( $id, $session->{serialized} );
    }
    foreach my $i (@$index) {
        my $t = $session->{data}->{$i};
        next unless ( defined($t) and ( length($t) > 0 ) );
        $self->{cache}->sadd( keyName("${i}_$t"), $id );
    }
}

sub update {
    my ( $self, $session ) = @_;
    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    my $id  = $session->{data}->{_session_id};
    my $ttl = $session->{args}->{TTL};

    # Nothing to clean up without index
    unless (@$index) {
        if ($ttl) {
            $self->{cache}->set( $id, $session->{serialized}, 'EX', $ttl );
        }
        else {
            $self->{cache}->set( $id, $session->{serialized} );
        }
        return;
    }

    # Read old data to clean up stale index entries
    my $old_raw = eval { $self->{cache}->get($id) };
    if ($@) {
        warn "Failed to read previous session '$id' from Redis: $@";
    }
    # Decode it like the session itself: Redis returns Latin-1, not UTF-8
    my $old_data;
    if ( defined $old_raw && length $old_raw ) {
        my $old = { serialized => $old_raw };
        eval { $session->{unserialize}->($old) };
        if ($@) {
            warn "Failed to decode previous session '$id': $@";
        }
        else {
            $old_data = $old->{data};
        }
    }

    # Store new data
    if ($ttl) {
        $self->{cache}->set( $id, $session->{serialized}, 'EX', $ttl );
    }
    else {
        $self->{cache}->set( $id, $session->{serialized} );
    }

    foreach my $i (@$index) {
        my $old_val = defined($old_data) ? $old_data->{$i} : undef;
        my $new_val = $session->{data}->{$i};

        # Remove old index entry if value changed
        if ( defined($old_val) && length($old_val) > 0 ) {
            if ( !defined($new_val)
                || length($new_val) == 0
                || $old_val ne $new_val )
            {
                eval { $self->{cache}->srem( keyName("${i}_$old_val"), $id ) };
            }
        }

        # Add new index entry
        if ( defined($new_val) && length($new_val) > 0 ) {
            $self->{cache}->sadd( keyName("${i}_$new_val"), $id );
        }
    }
}

sub materialize {
    my ( $self, $session ) = @_;
    $session->{serialized} =
      $self->{cache}->get( $session->{data}->{_session_id} )
      or die 'Object does not exist in data store.';
}

sub remove {
    my ( $self, $session ) = @_;
    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    my $id = $session->{data}->{_session_id};
    foreach my $i (@$index) {
        my $t;
        next unless ( $t = $session->{data}->{$i} );
        eval { $self->{cache}->srem( keyName("${i}_$t"), $id ); };
    }
    $self->{cache}->del($id);
}

sub _getRedis {
    my $class = shift;
    my $args  = shift;
    my $redisObj;

    # Manage undef encoding
    $args->{encoding} = undef
      if (  $args->{encoding}
        and $args->{encoding} eq "undef" );

    # If sentinels is not given as an array ref, try to parse
    # a comma delimited list instead
    if ( $args->{sentinels}
        and ref $args->{sentinels} ne 'ARRAY' )
    {
        $args->{sentinels} =
          [ split /[,\s]+/, $args->{sentinels} ];
    }

    if (    $args->{reuse}
        and $reused_connections{ $args->{reuse} } )
    {
        $redisObj = $reused_connections{ $args->{reuse} };
    }
    else {
        $redisObj = $redis->new( %{$args} );
        if ( $args->{reuse} ) {
            $reused_connections{ $args->{reuse} } = $redisObj;
        }
    }

    # Manage database
    $redisObj->select( $args->{database} )
      if defined $args->{database};
    return $redisObj;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Web::Session::Store::Redis - An implementation of
Apache::Session::Store

=head1 SYNOPSIS

 use Web::Session::Redis;
 
 tie %hash, 'Web::Session::Redis', $id, {
    # optional: default to localhost
    server => '127.0.0.1:6379',

    # optional: set a Redis TTL (in seconds) on session keys
    TTL => 86400,
 };

=head1 DESCRIPTION

This module is an implementation of Web::Session. It uses the
Redis storage system.

=head1 OPTIONS

=over

=item B<TTL>

Optional. If set, session keys will be stored with a Redis TTL (in seconds)
using C<SET key value EX ttl>. The TTL is refreshed on every update. This
acts as a safety net: sessions are automatically removed by Redis if the
application fails to delete them. Index sets are not expired by Redis, but
orphan index entries will be cleaned up by C<searchOn>, C<searchOnExpr>,
C<searchLt>, C<searchGt> or manual maintenance.

Without this option, session keys have no expiration and must be explicitly
deleted or purged.

=back

=head1 SEE ALSO

L<Web::Session>, L<Apache::Session::NoSQL>, L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
