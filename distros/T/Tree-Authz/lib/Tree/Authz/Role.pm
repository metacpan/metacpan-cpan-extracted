package Tree::Authz::Role;
use strict;
use warnings;
use Carp;

use overload '""' => 'name';

# NOTE: if this class ever holds any more data than just its name, it
# should probably be a singleton

=over

=item new( $role, $authz_class )

Represents a role.

=cut

# called by Tree::Authz::role
sub new {
    my ($proto, $role, $authz_class) = @_;

    my $self = [ $role, $authz_class ];

    bless $self, ref( $proto ) || $proto;

    # $self->_init;

    return $self;
}

=item name()

Returns the name of this role.

=item group_name()

DEPRECATED.

Use C<name> instead.

=cut

sub name { $_[0]->[0] }

=item authz

Returns the L<Tree::Authz> subclass used to instantiate this role.

=cut

sub authz { $_[0]->[1] }

sub group_name {
    carp "'group_name' is deprecated - use 'name' instead";
    goto &name;
}

=item list_roles

Returns a list of roles inherited by this role, including this role.

=cut

sub list_roles {
    my ($self) = @_;

    my @my_roles = grep { $self->can( $_ ) } $self->authz->list_roles;

    wantarray ? @my_roles : [ @my_roles ];
}


=item setup_permissions( $cando )

Instance method.

Adds methods to the class representing the role. I<$cando> is a single method
name, or arrayref of method names. No-op methods are added to the class
representing the group:

    my $spies = $authz->role( 'spies' );

    my $cando = [ qw( read_secret wear_disguise ) ];

    $spies->setup_permissions( $cando );

    if ( $spies->can( 'read_secret' ) ) {
        warn 'Compromised!';
    }

    warn 'Trust no-one' if $spies->can( 'wear_disguise' );

=cut

sub setup_permissions {
    my ($self, $cando) = @_;

    croak( 'Nothing to permit' ) unless $cando;
    my $class = ref( $self ) || croak( 'object method called on class name' );

    $class->_setup_perms( $cando );
}

sub _setup_perms {
    my ($class, $cando) = @_;

    my @permits = ref( $cando ) ? @$cando : ( $cando );

    no strict 'refs';
    foreach my $permit ( @permits ) {
        *{"${class}::$permit"} = sub {};
    }
}

=item setup_abilities( $name => $coderef, [ $name2 => $coderef2 ], ... )

Instance method.

Adds methods to the class representing the group. Keys give method names and
values are coderefs that will be installed as methods on the group class:

    my $spies = $authz->get_group( 'spies' );

    my %able = ( read_secret => sub {
                    my ($self, $file) = @_;
                    open( SECRET, $file );
                    local $/;
                    <SECRET>;
                    },

                 find_moles => sub { ... },

                );

    $spies->setup_abilities( %able );

    if ( $spies->can( 'read_secret' ) ) {
        print $spies->read_secret( '/path/to/secret/file' );
    }

    # or

    if ( my $read = $spies->can( 'read_secret' ) ) {
        print $spies->$read( '/path/to/secret/file' );
    }

    # with an unknown $group
    my $get_secret = $group->can( 'read_secret' )       ||     # spy
                     $group->can( 'steal_document' )    ||     # mole
                     $group->can( 'create_secret' )     ||     # spymaster
                     $group->can( 'do_illicit_thing' )  ||     # politician
                     sub {};                                   # boring life

    my $secret = $group->$get_secret;

=cut

sub setup_abilities {
    my ($self, %code) = @_;

    croak( 'Nothing to set up' ) unless %code;

    my $class = ref( $self ) || croak( 'object method called on class name' );

    $class->_setup_abil( %code );
}

sub _setup_abil {
    my ($class, %code) = @_;

    no strict 'refs';
    foreach my $method ( keys %code ) {
        *{"${class}::$method"} = $code{ $method };
    }
}

=item setup_plugins( $plugins )

Instance method.

Instead of adding a set of coderefs to a group's class, this method adds
a class to the C<@ISA> array of the group's class.

    package My::Spies;

    sub wear_disguise {}

    sub read_secret {
        my ($self, $file) = @_;
        open( SECRET, $file );
        local $/;
        <SECRET>;
    }

    package main;

    my $spies = $authz->get_group( 'spies' );

    $spies->setup_plugins( 'My::Spies' );

    if ( $spies->can( 'read_secret' ) ) {
        warn 'Compromised!';
        print $spies->read_secret( '/path/to/secret/file' );
    }

    warn 'Trust no-one' if $spies->can( 'wear_disguise' );

=back

=cut


sub setup_plugins {
    my ($self, $plugins) = @_;

    croak( 'Nothing to plug in' ) unless $plugins;

    my $class = ref( $self ) || croak( 'object method called on class name' );

    $class->_setup_plugins( $plugins );
}

sub _setup_plugins {
    my ($class, $plugins) = @_;

    my @plugins = ref( $plugins ) ? @$plugins : ( $plugins );

    no strict 'refs';

    push( @{"${class}::ISA"}, $_ ) for @plugins;
}

1;

