package Yote::YapiServer::Session;

use strict;
use warnings;
use base 'Yote::YapiServer::BaseObj';

use Digest::MD5;
use Time::Piece;
use Time::Seconds;

# Database column definitions
our %cols = (
    token        => 'VARCHAR(256)',
    user         => '*Yote::YapiServer::User',
    created      => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    expires      => 'DATE',
    last_access  => 'TIMESTAMP',
    ip_address   => 'VARCHAR(45)',        # IPv6 can be up to 45 chars
    exposed_objs => '*HASH<64>_INT',      # object_id => timestamp exposed
);

# Session duration in days
our $SESSION_DURATION_DAYS = 90;

#----------------------------------------------------------------------
# Class methods
#----------------------------------------------------------------------

sub generate_token {
    my ($class) = @_;

    # Generate cryptographically random token
    my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
    my $random = join '', map { $chars[rand @chars] } 1..32;

    # Add timestamp component for uniqueness
    my $timestamp = time();

    # Create token with HMAC-like signature
    my $token = $random . '_' . $timestamp;
    my $signature = substr(Digest::MD5::md5_hex($token . ($ENV{SPIDERPUP_SECRET} // 'dev_secret')), 0, 8);

    return $token . '_' . $signature;
}

sub calculate_expiry {
    my ($class, $days) = @_;
    $days //= $SESSION_DURATION_DAYS;
    my $now = localtime;
    my $expires = $now + ONE_DAY * $days;
    return $expires->strftime("%Y-%m-%d");
}

#----------------------------------------------------------------------
# Object capability tracking
#----------------------------------------------------------------------

sub expose_object {
    my ($self, $obj) = @_;
    return unless $obj && $obj->can('id');

    my $id = $obj->id;
    $self->get_exposed_objs->{$id} = time();
    return $id;
}

sub expose_objects {
    my ($self, @objs) = @_;
    my @ids;
    for my $obj (@objs) {
        push @ids, $self->expose_object($obj);
    }
    return @ids;
}

sub can_access {
    my ($self, $obj_or_id) = @_;
    return 0 unless defined $obj_or_id;

    my $id;
    if (ref $obj_or_id) {
        return 0 unless $obj_or_id->can('id');
        $id = $obj_or_id->id;
    } else {
        # Handle "_obj_123" format
        if ($obj_or_id =~ /^_obj_(\d+)$/) {
            $id = $1;
        } else {
            $id = $obj_or_id;
        }
    }

    return $self->get_exposed_objs->{$id} ? 1 : 0;
}

sub revoke_access {
    my ($self, $obj_or_id) = @_;
    my $id = ref $obj_or_id ? $obj_or_id->id : $obj_or_id;
    delete $self->get_exposed_objs->{$id};
}

sub clear_exposed {
    my ($self) = @_;
    %{$self->get_exposed_objs} = ();
}

#----------------------------------------------------------------------
# Session management
#----------------------------------------------------------------------

sub is_expired {
    my ($self) = @_;
    my $expires = $self->get_expires;
    return 1 unless $expires;

    my $now = localtime->strftime("%Y-%m-%d");
    return $expires lt $now;
}

sub touch {
    my ($self) = @_;
    $self->set_last_access(localtime->strftime("%Y-%m-%d %H:%M:%S"));
}

sub refresh_expiry {
    my ($self, $days) = @_;
    $self->set_expires($self->calculate_expiry($days));
}

1;

__END__

=head1 NAME

Yote::YapiServer::Session - Session management with object capability tracking

=head1 DESCRIPTION

Manages user sessions and tracks which objects have been exposed to the client.
This provides security by ensuring clients can only access objects explicitly
granted to their session.

=head1 OBJECT CAPABILITY MODEL

When the server returns an object to the client, it calls expose_object() to
record that the client has been given access. Subsequent requests that reference
that object are validated against the exposed_objs list.

This prevents clients from accessing arbitrary objects by guessing IDs.

=head1 METHODS

=head2 generate_token()

Class method. Generates a cryptographically random session token with signature.

=head2 expose_object($obj)

Records that an object has been exposed to this session. Returns the object ID.

=head2 can_access($obj_or_id)

Returns true if the object/ID has been exposed to this session.

=head2 is_expired()

Returns true if the session has expired.

=head2 touch()

Updates last_access timestamp.

=cut
