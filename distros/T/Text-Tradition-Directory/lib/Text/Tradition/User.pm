package Text::Tradition::User;

use strict;
use warnings;

use Moose;
with qw(KiokuX::User);

## 'id' provided by KiokuX::User stores our username (email for local users, openid url for openid/google)
has 'password'   => (is => 'rw', required => 1);
has 'email' => (is => 'rw', lazy => 1, builder => '_build_email');
## Change this default active value if you want/need to have an admin confirm a user after they self-create.
has 'active'     => (is => 'rw', default => sub { 1; });
has 'role'       => (is => 'rw', default => sub { 'user' });
# 'traits' => ['Array'] ?
# https://metacpan.org/module/Moose::Meta::Attribute::Native::Trait::Array
has 'traditions' => (is => 'rw', 
                     traits => ['Array'],
                     handles => {
                         'add_tradition' => 'push',
                     },
                     isa => 'ArrayRef[Text::Tradition]', 
                     default => sub { [] }, 
                     required => 0);

after add_tradition => sub { 
    my ($self, $tradition) = @_;
    $tradition->user($self) 
        unless $tradition->has_user && $tradition->user->id eq $self->id;
};

sub _build_email {
    my ($self) = @_;

    ## no email set, so use username/id
    return $self->id;
}

sub remove_tradition {
    my ($self, $tradition) = @_;

    ## FIXME: Is "name" a good unique field to compare traditions on?
    my @traditions = @{$self->traditions};
    @traditions = grep { $tradition != $_ } @traditions;

    $tradition->clear_user;
    $self->traditions(\@traditions);
}

sub is_admin {
    my ($self) = @_;

    return $self->role && $self->role eq 'admin';
}

1;

=head1 NAME

Text::Tradition::User - Users which own traditions, and can login to the web app

=head1 SYNOPSIS

    ## Users are managed by Text::Tradition::Directory

    my $userstore = Text::Tradition::Directory->new(dsn => 'dbi:SQLite:foo.db');
    my $newuser = $userstore->add_user({ username => 'fred',
                                         password => 'somepassword' });

    my $fetchuser = $userstore->find_user({ username => 'fred' });
    if($fetchuser->check_password('somepassword')) { 
       ## login user or .. whatever
    }

    my $user = $userstore->deactivate_user({ username => 'fred' });
    if(!$user->active) { 
      ## shouldnt be able to login etc
    }

    foreach my $t (@{ $user->traditions }) {
      ## do something with traditions owned by this user.
    }

=head1 DESCRIPTION

User objects representing owners of L<Text::Tradition>s and authenticated users.

=head2 ATTRIBUTES

=head3 id

Inherited from KiokuX::User, stores the 'username' (login) of the user.

=head3 password

User's password, encrypted on creation (by
L<KiokuX::User::Util/crypt_password>.

=head3 active

Active flag, defaults to true (1). Will be set to false (0) by
L<Text::Tradition::UserStore/deactivate_user>.

=head3 traditions

Returns an ArrayRef of L<Text::Tradition> objects belonging to this user.

=head1 METHODS

=head2 check_password

Inherited from KiokuX::User, verifies a given password string against
the stored encrypted version.

=head2 add_tradition( $tradition )

Assigns the given tradition to this user.

=head2 remove_tradition( $tradition )

Removes the specified tradition from the control of this user.

=head2 is_admin

Returns true if this user has administrative privileges.



