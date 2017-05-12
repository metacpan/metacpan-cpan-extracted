# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Realm::RealmBase;

=pod

=head1 NAME

Wombat::Realm::RealmBase - internal realm base clas

=head1 SYNOPSIS

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Realm>. Subclasses should
implement C<getName()>, C<getPassword()>, and C<getPrincipal()>.

=cut

use base qw(Wombat::Realm);
use fields qw(algorithm container digest started);
use strict;
use warnings;

use Wombat::Exception ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Realm::RealmBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{algorithm} = undef;
    $self->{container} = undef;
    $self->{digest} = undef;
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getAlgorithm()

Return the digest algorithm used for authenticating credentials. If no
algorithm is specified, credentials will be used as submitted.

=cut

sub getAlgorithm {
    my $self = shift;

    return $self->{algorithm};
}

=pod

=item setAlgorithm($algorithm)

Set the digest algorithm used for authenticating
credentials. Supported algorithms include: MD5, SHA1, HMAC, MD2, and
anything else provided by the L<Digest> library.

B<Parameters:>

=over

=item $algorithm

the digest algorithm

=back

=cut

sub setAlgorithm {
    my $self = shift;
    my $algorithm = shift;

    $self->{algorithm} = $algorithm;

    return 1;
}

=pod

=item getContainer()

Return the Container associated with this Realm.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container associated with this Realm.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> associated with this Realm

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item authenticate ($username, $credentials)

Return the Principal associated with the specified username and
credentials, if there is one, or C<undef> otherwise.

B<Parameters>

=over

=item $username

username of the principal to be looked up

=item $credentials

password or other credentials to use in authenticating this username

=back

=cut

sub authenticate {
    my $self = shift;
    my $username = shift;
    my $credentials = shift;

    my $password = $self->getPassword($username);

    return undef unless defined $password && $password eq $credentials;

    return $self->getPrincipal($username);
}

=pod

=item hasRole($principal, $role)

Return true if the specified Principal has the specified security
role within the context of this Realm, or false otherwise.

B<Parameters:>

=over

=item $principal

the B<Wombat::Realm::Genericrincipal> for whom the role is to be
checked

=item $role

the name of the security role to be checked

=back

=cut

sub hasRole {
    my $self = shift;
    my $principal = shift;
    my $role = shift;

    return undef unless defined $principal && defined $role &&
        $principal->isa('Wombat::Realm::GenericPrincipal');

    my $prealm = $principal->getRealm();
    return undef unless $prealm;

    my $prealmname = $prealm->getName();
    return undef unless $prealmname eq $self->getName();

    return $principal->hasRole($role);
}

=pod

=back

=head1 PACKAGE METHODS

=over

=item digest()

Digest a submitted password using the configured algorithm and convert
the result to a corresponding hexadecimal string. If an exception is
thrown, the plain credentials string is returned.

B<Parameters:>

=over

=item $credentials

the password or other credentials to use in authentication

=back

=cut

sub digest {
    my $self = shift;
    my $credentials = shift;

    return $credentials unless $self->{digest};

    $self->{digest}->add($credentials);
    return $self->{digest}->hexdigest();
}

=pod

=item getName()

Return a short name for this Realm implementation. Must be overridden
by subclasses.

=cut

sub getName {}

=pod

=item getPassword($username)

Return the password associated with the given Principal's user
name. Should be overridden by subclasses.

B<Parameters:>

=over

=item $username

the username of the Principal

=back

=cut

sub getPassword {}

=pod

=item getPrincipal($username)

Return the Principal associated with the given user name. Should be
overridden by subclasses.

B<Parameters:>

=over

=item $username

the username of the Principal

=back

=cut

sub getPrincipal {}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this Realm. This method should be called
before any of the public methods of the Realm are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the Realm has already been started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: realm already started";
        Wombat::LifecycleException->throw($msg);
    }

    if ($self->{algorithm}) {
        my $class = join '::', 'Digest', $self->{algorithm};
        eval "require $class";
        if ($@) {
            my $msg =
                "start: unsupported digest algorithm [$self->{algorithm}]";
            Wombat::LifecycleException->throw($msg);
        }

        $self->{digest} = $class->new();
    }

    $self->{started} = 1;
    $self->log(sprintf("%s started", $self->getName()), undef, 'INFO');

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this Realm. Once this method
has been called, no public methods of the Realm should be
utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the Realm is not started

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: realm not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};
    $self->log(sprintf("%s stopped", $self->getName()), undef, 'DEBUG');

    return 1;
}

=pod

=back

=cut

# private methods

sub log {
    my $self = shift;

    $self->{container}->log(@_) if $self->{container};

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<Digest>,
L<Wombat::Container>,
L<Wombat::Exception>,
L<Wombat::Realm>,
L<Wombat::Realm::GenericPrincipal>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
