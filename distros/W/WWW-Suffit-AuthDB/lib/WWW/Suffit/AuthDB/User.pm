package WWW::Suffit::AuthDB::User;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::User - WWW::Suffit::AuthDB user class

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB::User;

=head1 DESCRIPTION

This module provides AuthDB user methods

=head1 ATTRIBUTES

This class implements the following attributes

=head2 address

    address => '127.0.0.1'

The remote client IP address (IPv4 or IPv6)

    $user = $user->address("::1");
    my $address = $user->address;

Default: '127.0.0.1'

=head2 algorithm

    $user = $user->algorithm( 'SHA256' );
    my $algorithm = $user->algorithm;

Sets or returns algorithm of hash function for password store.
See L</password> attribute

Default: 'SHA256'

=head2 attributes

    $user = $user->attributes( '{"foo": 123, "disabled": 0}' );
    my $attributes = $user->attributes;

Sets or returns additional attributes of the user in JSON format

Default: none

=head2 cached

    $user = $user->cached( 12345.123456789 );
    my $cached = $user->cached;

Sets or returns time of caching user data

Default: 0

=head2 cachekey

    $user = $user->cachekey( 'abcdef1234567890' );
    my $cachekey = $user->cachekey;

Sets or returns the cache key string

=head2 comment

    $user = $user->comment( 'Blah-Blah-Blah' );
    my $comment = $user->comment;

Sets or returns comment for selected user

Default: undef

=head2 created

    $user = $user->created( time() );
    my $comment = $user->created;

Sets or returns time of user create

Default: 0

=head2 disabled

    $user = $user->disabled( 1 );
    my $disabled = $user->disabled;

Sets and returns boolean ban-status of the user

Since C<1.01> this method is deprecated! See L</is_enabled>

=head2 email

    $user = $user->email('alice@example.com');
    my $email = $user->email;

Sets and returns email address of user

=head2 error

    $user = $user->error( 'Oops' );
    my $error = $user->error;

Sets or returns error string

=head2 expires

    $user = $user->expires( 300 );
    my $expires = $user->expires;

Sets or returns cache/object expiration time in seconds

Default: 300 (5 min)

=head2 flags

    $user = $user->flags( 123 );
    my $flags = $user->flags;

Sets or returns flags of user

Default: 0

=head2 groups

    $user = $user->groups([qw/ administrator wheel /]);
    my $groups = $user->groups; # ['administrator', 'wheel']

Sets and returns groups of user (array of groups)

=head2 id

    $user = $user->id( 2 );
    my $id = $user->id;

Sets or returns id of user

Default: 0

=head2 is_authorized

This attribute returns true if the user is authorized

Default: false

=head2 is_cached

This attribute returns true if the user data was cached

Default: false

=head2 name

    $user = $user->name('Mark Miller');
    my $name = $user->name;

Sets and returns full name of user

=head2 not_after

    $user = $user->not_after( time() );
    my $not_after = $user->not_after;

Sets or returns the time after which user data is considered invalid

=head2 not_before

    $user = $user->not_before( time() );
    my $not_before = $user->not_before;

Sets or returns the time before which user data is considered invalid

=head2 password

    $user = $user->password(sha256_hex('MyNewPassphrase'));
    my $password = $user->password;

Sets and returns hex notation of user password digest (sha256, eg.).
See L</algorithm> attribute

=head2 private_key

    $user = $user->private_key('...');
    my $private_key = $user->private_key;

Sets and returns private key of user

=head2 public_key

    $user = $user->public_key('...');
    my $public_key = $user->public_key;

Sets and returns public key of user

=head2 role

    $user = $user->role('Regular user');
    my $role = $user->role;

Sets and returns role of user

=head2 username

    $user = $user->username('new_username');
    my $username = $user->username;

Sets and returns username

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 allow_ext

    say "yes" if $user->allow_ext;

Returns true if user has access to external routes

=head2 allow_int

    say "yes" if $user->allow_int;

Returns true if user has access to internal routes

=head2 forever

    say "yes" if $user->forever;

Returns true if user can use endless API tokens

=head2 is_admin

    say "yes" if $user->is_admin;

If user is admin then returns true

=head2 is_enabled

    say "yes" if $user->is_enabled;

Returns status of user - enabled (true) or disabled (false)

=head2 is_valid

    $user->is_valid or die "Incorrect user";

Returns boolean status of user's data

=head2 mark

Marks object as cached

=head2 to_hash

    my $short = $user->to_hash();
    my $full = $user->to_hash(1);

Returns user data as hash in short or full view

=head2 use_flags

    say "yes" if $user->use_flags;

This method returns a binary indicator - whether flags should be used or not

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base -base;

use Mojo::Util qw/md5_sum deprecated steady_time/;

use constant {
    # User Flags (See main.js too!)
    # Set: VAL = VAL | UFLAG_*
    # Get: VAL & UFLAG_*
    DEFAULT_ADDRESS     => '127.0.0.1',
    UFLAG_USING         => 1,  # 0  Use rules of flags
    UFLAG_ENABLED       => 2,  # 1  User is enabled
    UFLAG_IS_ADMIN      => 4,  # 2  User is admin
    UFLAG_ALLOW_INT     => 8,  # 3  User has access to internal routes
    UFLAG_ALLOW_EXT     => 16, # 4  User has access to external routes
    UFLAG_FOREVER       => 32, # 5  User can use endless tokens
};

has address     => DEFAULT_ADDRESS;
has algorithm   => 'SHA256';
has attributes  => '';
has comment     => '';
has created     => 0;
has disabled    => sub { deprecated 'The "disabled" method is deprecated! Use "is_enabled"'; 0; };
has email       => '';
has error       => '';
has expires     => 0;
has flags       => 0;
has groups      => sub { return [] };
has id          => 0;
has name        => '';
has not_after   => undef;
has not_before  => undef;
has password    => '';
has private_key => '';
has public_key  => '';
has role        => 'Regular user';
has username    => undef;
has is_cached   => 0; # 0 or 1
has cached      => 0; # steady_time() of cached
has cachekey    => '';
has is_authorized => 0;

sub is_valid {
    my $self = shift;

    unless ($self->id) {
        $self->error("E1310: User not found");
        return 0;
    }
    unless (defined($self->username) && length($self->username)) {
        $self->error("E1311: Incorrect username stored");
        return 0;
    }
    unless (defined($self->password) && length($self->password)) {
        $self->error("E1312: Incorrect password stored");
        return 0;
    }
    if ($self->expires && $self->expires < time) {
        $self->error("E1313: The user data is expired");
        return 0;
    }

    return 1;
}
sub mark {
    my $self = shift;
    return $self->is_cached(1)->cached(shift || steady_time);
}
sub to_hash {
    my $self = shift;
    my $all = shift || 0;
    return (
        uid      => $self->id || 0,
        username => $self->username // '',
        name     => $self->name // '',
        email    => $self->email // '',
        email_md5=> $self->email ? md5_sum(lc($self->email)) : '',
        role     => $self->role // '',
        groups   => $self->groups || [],
        expires  => $self->expires || 0,
        $all ? (
            algorithm   => $self->algorithm // '',
            attributes  => $self->attributes // '',
            comment     => $self->comment // '',
            created     => $self->created || 0,
            flags       => $self->flags || 0,
            not_after   => $self->not_after || 0,
            not_before  => $self->not_before || 0,
            public_key  => $self->public_key // '',
        ) : (),
    );
}
sub use_flags {
    my $self = shift;
    my $flags = ($self->flags || 0) * 1;
    return ($flags & UFLAG_USING) ? 1 : 0;
}
sub is_enabled {
    my $self = shift;
    my $flags = ($self->flags || 0) * 1;
    my $now = time;

    # Check dates first
    my $not_before = ($self->not_before || 0) * 1;
    my $not_after = ($self->not_after || 0) * 1;
    my $status = (
            ($not_before ? (($not_before >= $now) ? 0 : 1) : 1)
             && ($not_after ? (($not_after <= $now) ? 0 : 1) : 1)
        ) ? 1 : 0;
    return 0 unless $status; # Disabled by dates

    # Check flags?
    return $status unless $self->use_flags;
    return ($flags & UFLAG_ENABLED) ? 1 : 0;
}
sub is_admin {
    my $self = shift;
    return 1 unless $self->use_flags; # Returns true by default if not using flags
    my $flags = ($self->flags || 0) * 1;
    return ($flags & UFLAG_IS_ADMIN) ? 1 : 0;
}
sub allow_int {
    my $self = shift;
    return 1 unless $self->use_flags; # Returns true by default if not using flags
    my $flags = ($self->flags || 0) * 1;
    return ($flags & UFLAG_ALLOW_INT) ? 1 : 0;
}
sub allow_ext {
    my $self = shift;
    return 1 unless $self->use_flags; # Returns true by default if not using flags
    my $flags = ($self->flags || 0) * 1;
    return ($flags & UFLAG_ALLOW_EXT) ? 1 : 0;
}
sub forever {
    my $self = shift;
    return 1 unless $self->use_flags; # Returns true by default if not using flags
    my $flags = ($self->flags || 0) * 1;
    return ($flags & UFLAG_FOREVER) ? 1 : 0;
}

1;

__END__
