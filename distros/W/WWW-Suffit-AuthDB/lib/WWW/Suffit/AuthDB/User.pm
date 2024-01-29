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

Check the user object

=head2 mark

Marks object as cached

=head2 to_hash

    my $short = $user->to_hash();
    my $full = $user->to_hash(1);

Returns user data as hash in short or full view

=head2 use_flags

    say "yes" if $user->use_flags;

This method returns a binary indicator - whether flags should be used or not

=head1 ATTRIBUTES

=over 8

=item disabled

    $user->disabled( 1 );
    my $disabled = $user->disabled;

Sets and returns boolean ban-status of the user

Since 1.01 this method is deprecated! See is_enabled

=item email

    $user->email('alice@example.com');
    my $email = $user->email;

Sets and returns email address of user

=item groups

    $user->groups([qw/ administrator wheel /]);
    my $groups = $user->groups; # ['administrator', 'wheel']

Sets and returns groups of user (array of groups)

=item is_valid

    $user->is_valid or die "Incorrect user";

Returns boolean status of user's data

=item name

    $user->name('Mark Miller');
    my $name = $user->name;

Sets and returns full name of user

=item password

    $user->password(sha256_hex('MyNewPassphrase'));
    my $password = $user->password;

Sets and returns password (hex sha256 digest) of user

=item role

    $user->role('Regular user');
    my $role = $user->role;

Sets and returns role of user

=item username

    $user->username('new_username');
    my $username = $user->username;

Sets and returns username

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Mojo::Base -base;

use Mojo::Util qw/md5_sum deprecated/;

use constant {
    # User Flags (See main.js too!)
    # Set: VAL = VAL | UFLAG_*
    # Get: VAL & UFLAG_*
    UFLAG_USING         => 1,  # 0  Use rules of flags
    UFLAG_ENABLED       => 2,  # 1  User is enabled
    UFLAG_IS_ADMIN      => 4,  # 2  User is admin
    UFLAG_ALLOW_INT     => 8,  # 3  User has access to internal routes
    UFLAG_ALLOW_EXT     => 16, # 4  User has access to external routes
    UFLAG_FOREVER       => 32, # 5  User can use endless tokens
};

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
has is_cached   => 0;
has is_authorized => 0;

sub is_valid {
    my $self = shift;

    unless ($self->id) {
        $self->error("E1330: User not found");
        return 0;
    }
    unless (defined($self->username) && length($self->username)) {
        $self->error("E1331: Incorrect username stored");
        return 0;
    }
    unless (defined($self->password) && length($self->password)) {
        $self->error("E1332: Incorrect password stored");
        return 0;
    }
    if ($self->expires && $self->expires < time) {
        $self->error("E1333: The user data is expired");
        return 0;
    }

    return 1;
}
sub mark {
    my $self = shift;
    $self->is_cached(1);
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

    # Check dates first
    my $not_before = ($self->not_before || 0) * 1;
    my $not_after = ($self->not_after || 0) * 1;
    my $status = (
            ($not_before ? (($not_before >= time) ? 0 : 1) : 1)
             && ($not_after ? (($not_after <= time) ? 0 : 1) : 1)
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
