package Tree::Authz;
use strict;
use warnings;
use Carp;


# persistence doesn't work - propagating changes to other processes

# TODO - plugin sets - specify a search path e.g. My::App::Roles
# any module My::App::Roles::rolename for a rolename defined in the authz
# is automatically loaded into that role

use Lingua::EN::Inflect::Number ();
use Symbol;

use Tree::Authz::Role;

use base 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata( '_AllRoles' );
__PACKAGE__->mk_classdata( '_database' );
__PACKAGE__->mk_classdata( '__namespace' );

__PACKAGE__->_AllRoles( {} );

our $VERSION = '0.03';

=head1 NAME

Tree::Authz - inheritance-based authorization scheme

=head1 VERSION

0.02_1

=head1 DEVELOPER RELEASE

Re-organised to return objects (blessed into the new class C<Tree::Authz::Role>),
instead of strings, which are now referred to as C<roles> rather than C<groups>
in the documentation. Some method names changed to reflect the terminology.

=head1 SYNOPSIS

    use Tree::Authz;

    my $roles = { superuser    => [ qw( spymasters politicians ) ],
                  spymasters   => [ qw( spies moles ) ],
                  spies        => [ 'informants' ],
                  informants   => [ 'base' ],
                  moles        => [ 'base' ],
                  politicians  => [ 'citizens' ],
                  citizens     => [ 'base' ],
                  };

    my $authz = Tree::Authz->setup_hierarchy( $roles, 'SpyLand' );

    my $superuser = $authz->role( 'superuser' );
    my $spies     = $authz->role( 'spies' );
    my $citizens  = $authz->role( 'citizens' );
    my $base      = $authz->role( 'base' );

    $spies   ->setup_permissions( [ qw( read_secrets wear_disguise ) ] );
    $citizens->setup_permissions( 'vote' );
    $base    ->setup_permissions( 'breathe' );

    foreach my $role ( $superuser, $spies, $citizens, $base ) {
        foreach my $ability ( qw( unspecified_ability
                                  spy
                                  spies
                                  read_secrets
                                  wear_disguise
                                  vote
                                  breathe
                                  can ) ) {

            if ( $role->can( $ability ) ) {
                print "$role can '$ability'\n";
            }
            else {
                print "$role cannot '$ability'\n";
            }
        }
    }

    # prints:

    superuser can 'unspecified_ability'     # superpowers!
    superuser can 'spy'
    superuser can 'spies'
    superuser can 'read_secrets'
    superuser can 'wear_disguise'
    superuser can 'vote'
    superuser can 'breathe'
    superuser can 'can'
    spies cannot 'unspecified_ability'
    spies can 'spy'
    spies can 'spies'
    spies can 'read_secrets'
    spies can 'wear_disguise'
    spies can 'vote'
    spies can 'breathe'
    spies can 'can'
    citizens cannot 'unspecified_ability'
    citizens cannot 'spy'
    citizens cannot 'spies'
    citizens cannot 'read_secrets'
    citizens cannot 'wear_disguise'
    citizens can 'vote'
    citizens can 'breathe'
    citizens can 'can'
    base cannot 'unspecified_ability'
    base cannot 'spy'
    base cannot 'spies'
    base cannot 'read_secrets'
    base cannot 'wear_disguise'
    base cannot 'vote'
    base cannot 'breathe'                   # !
    base cannot 'can'                       # !!

    # storing code on the nodes (roles) of the tree
    $spies->setup_abilities( read_secret => $coderef );

    print $spies->read_secret( '/path/to/secret/file' );

    $spies->setup_plugins( 'My::Spies::Skills' );

    $spies->fly( $jet ); # My::Spies::Skills::fly

=head1 DESCRIPTION

Class for inheritable, role-based permissions system (Role Based Access
Control - RBAC).

Custom methods can be placed on role objects. Authorization can be performed
either by checking whether the role name matches the required name, or by
testing (via C<can>) whether the role can perform the method required.

Two role are specified by default. At the top, I<superuser>s can do anything
(C<< $superuser->can( $action ) >> always returns a coderef). At the bottom, the
I<base> role can do nothing (C<< $base->can( $action ) >> always returns undef).

All roles are automatically capable of authorizing actions named for the
singular and plural of the role name.

=head2 ROADMAP

I'm planning to implement some of the main features and terminology described
in this document, which describes a standard for Role Based Access Control:

    http://csrc.nist.gov/rbac/rbacSTD-ACM.pdf

Thanks to Kingsley Kerce for providing the link.

=head1 METHODS

This class is a static class - all methods are class methods.

Some methods return L<Tree::Authz::Role|Tree::Authz::Role> subclass objects.

=head2 Namespaces and class methods

This class is designed to work in environments where multiple applications
run within the same process (i.e. websites under C<mod_perl>). If the optional
namespace parameter is supplied to C<setup_hierarchy>, the roles are isolated
to the specified namespace. All methods should be called through the
class name returned from C<setup_hierarchy>.

If your program is not operating in such an environment (e.g. CGI scripts),
then you can completely ignore this parameter, and call class methods either
through C<Tree::Authz>, or through the string returned from C<setup_hierarchy>
(which, funnily enough, will be 'Tree::Authz').

=over 4

=item role( $role_name )

Factory method, returns a L<Tree::Authz::Role|Tree::Authz::Role> subclass
object.

Sets up two permitted actions on the group - the singular and plural of
the group name. B<This might be too cute, and could change to just the group
name in a near future release>. Opinions welcome.

=item new( $role_name )

DEPRECATED.

Use C<role> instead.

=item get_group( $group_name )

DEPRECATED.

Use C<role> instead.

=cut

sub role {
    my ($proto, $role) = @_;

    croak 'No role name' unless $role;

    unless ( $proto->role_exists( $role ) ) {
        carp( "Unknown role: $role - using 'base' instead" );
        $role = 'base';
    }

    my $authz_class = ref( $proto ) || $proto;

    my $class = "${authz_class}::Role::$role";

    return $class->new( $role, $authz_class );
}

sub new {
    carp "'new' is deprecated - use 'role' instead";
    goto &role;
}

sub get_group {
    carp "'get_group' is deprecated - use 'role' instead";
    goto &new;
}




=item role_exists( $role_name )

Returns true if the specified group exists B<anywhere> within the hierarchy.

=item group_exists( $group_name )

DEPRECATED.

Use C<role_exists> instead.

=cut

sub role_exists { exists $_[0]->_AllRoles->{ $_[1] } }

sub group_exists {
    carp "'group_exists' is deprecated - use 'role_exists' instead";
    goto &role_exists;
}

=item subrole_exists( $subrole_name, [ $role_name ] )

B<Method not implemented yet>.

Give me a nudge if this would be useful.

Returns true if the specified role exists anywhere in the hierarchy
underneath the current or specified role.

=cut

sub subrole_exists { croak 'subrole_exists method not implemented yet - email me' }

=item list_roles()

Returns an array or arrayref of all the role names in the hierarchy, sorted by
name.

=item list_groups()

DEPRECATED.

Use C<list_roles> instead.

=cut

sub list_roles {
    my @roles = sort keys %{ $_[0]->_AllRoles };
    wantarray ? @roles : [ @roles ];
}

sub list_groups {
    carp "'list_groups' is deprecated - use 'list_roles' instead";
    goto &list_roles;
}


=item dump_hierarchy( [ $namespace ] )

Get a simple printout of the structure of your hierarchy.

This method C<require>s L<Devel::Symdump|Devel::Symdump>.

If you find yourself parsing the output and using it somehow in your code, let
me know, and I'll find a Better Way to provide the data. This method is just
intended for quick and dirty printouts and could B<change at any time>.

=cut

sub dump_hierarchy {
    my ($proto) = @_;

    my $class = ref( $proto ) || $proto;

    require Devel::Symdump;

    my @classes = split( "\n", Devel::Symdump->isa_tree );

    my @wanted;
    my $start = 0;
    my $end = 0;
    my $supers = "${class}::Role::superuser";

    foreach my $possible ( @classes ) {
        $start = 1 if $possible =~ /^$supers/;
        if ( $start && $possible !~ /^$supers/ ) {
            $end = 1 if $possible =~ /^\w/;
        }
        push( @wanted, $possible ) if ( $start && ! $end && $possible =~ __PACKAGE__ );
    }

    return join( "\n", @wanted );
}

=item setup_hierarchy( $groups, [ $namespace ] )

Class method.

I<$groups> has:

    keys   - group names
    values - arrayrefs of subgroup name(s)

Sets up a hierarchy of Perl classes representing the group structure.

The hierarchy will be contained within the I<$namespace> top level if supplied.
This makes it easy to set up several independent hierarchies to use within the
same process, e.g. for different websites under C<mod_perl>.

Returns a class name through which group objects can be retrieved and other
class methods called. This will be 'Tree::Authz' if no namespace is specified.

If called with a I<$namespace> argument, then all loaded packages within the
C<$namespace::Tree::Authz> symbol table hierarchy are removed (using
L<Symbol::delete_package|Symbol::delete_package> from the symbol
table. This is experimental and may lead to bugs, the jury is still out. The
purpose of this is to allow re-initialisation of the setup within a long-running
process such as C<mod_perl>. It could also allow dynamic updates to the
hierarchy.

=cut

sub setup_hierarchy {
    my ($proto, $roles_data, $namespace) = @_;

    croak( 'No roles data' ) unless $roles_data;

    my $class = ref( $proto ) || $proto;
    $class = "${namespace}::$class" if $namespace;

    # If we are reloading, remove any existing hierarchy from the symbol table.
    # But not if there's no namespace, because then we would lose Tree::Authz
    # itself
    # Symbol::delete_package( $class ) if $namespace;

    my $roles_class = 'Tree::Authz::Role';
    $roles_class = "${namespace}::$roles_class" if $namespace;

    my %roles;

    foreach my $role ( keys %$roles_data ) {
        my @isa = map { "${roles_class}::$_" } @{ $roles_data->{ $role } };
        my $role_class = "${roles_class}::${role}";
        $roles{ $role } = $role_class;
        no strict 'refs';
        @{"${role_class}::ISA"} = @isa;
    }

    my $supers_class = "${roles_class}::superuser";
    my $base_class   = "${roles_class}::base";

    {
        no strict 'refs';

        # base for authz class
        # push( @{"${class}::ISA"}, 'Tree::Authz' ) if $namespace;
        # set, rather than push onto, because this has to be repeatably callable
        # to allow updates after editing
        @{"${class}::ISA"} = ( 'Tree::Authz' ) if $namespace;

        # add a base group
        # push( @{"${base_class}::ISA"}, 'Tree::Authz::Role' ); # $roles_class );
        @{"${base_class}::ISA"} = ( 'Tree::Authz::Role' );

        # superuser always returns a subref from 'can', even if the specified
        # method doesn't exist.
        *{"${supers_class}::can"} =
            sub { UNIVERSAL::can( $_[0], $_[1] ) || sub {} };

        # base group cannot do anything
        *{"${base_class}::can"} = sub {
            my ($proto, @args) = @_;
            my $class = ref( $proto ) || $proto;
            return if $class =~ /::base$/;
            return UNIVERSAL::can( $proto, @args );
        };
    }

    # classdata methods have to come down here, after @ISA is set up for $class
    $class->_AllRoles( {} );
    $class->_AllRoles->{ $_ } = $roles{ $_ } for keys %roles;
    $class->_AllRoles->{ superuser } = $supers_class;
    $class->_AllRoles->{ base }      = $base_class;

    # __reload needs this
    $class->__namespace( $namespace );

    foreach my $role ( keys %roles ) {
        my @cando = ( Lingua::EN::Inflect::Number::to_PL( $role ),
                      Lingua::EN::Inflect::Number::to_S(  $role ),
                      );
        $class->setup_permissions_on_role( $role, \@cando )
    }

    return $class;
}

=back

=head2 Persistence

L<Tree::Authz|Tree::Authz> can be used independently of a persistence mechanism
I<via> C<setup_hierarchy>. However, if you want to manipulate the hierarchy at
runtime, a persistence mechanism is required. The implementation is left up to
you, but the API is defined. The persistence API should be
implemented by the object passed to C<setup_from_database>.

=over

=item setup_from_database( $database, [ $namespace ] )

I<$database> should be an object that responds to the persistence API defined
below. The object is stored as class data and is available via the C<_database>
method.

=back

=head3 Pass-through methods

The following methods are passed on to the database object, after checking
whether any changes would result in a recursive inheritance pattern, in which
case they return false. The database methods should return true on success.

=over

=item get_roles_data()

Returns a hashref. Keys are role names, values are arrayrefs of subroles.

C<setup_from_database> calls this method on the database object, then passes
the data on to C<setup_hierarchy>.

=item add_role( $new_role, $parent, [ $children ] )

Adds a new role to the scheme.

I<$parent> is required, so no new top-level
roles can be inserted. It's up to you to decide whether to raise an error or
just return if I<$parent> is omitted.

I<$children> can be a role name or an arrayref of role names. Defaults to
C<'base'> if omitted. It might be worth checking if these roles already exist.

At the moment I am assuming no multiple inheritance, but things are shaping up
to look like there's no great difficulty about allowing it. If allowed, this
method should check if I<$new_role> already exists. If it does, ignore any
I<$children> (probably raise a warning), add <$new_role> to the sub-roles list
of I<$parent>, and return without trying to insert I<$new_role> into the
database (because it already exists).

=item remove_role( $role )

Removes the role from the database, including finding and removing any
occurrences of I<$role> in the sub-role lists of other roles.

Returns the list of subroles for the role that was removed, in case you want
to put them somewhere else.

=item move_role( $role, $to )

Makes I<$role> a sub-role of I<$to>, and deletes it from the sub-roles list of
its current parent.

=item add_subrole( $role, $subrole )

Adds a subrole to a role. Must remove C<'base'> from the subroles list if
present.

=item remove_subrole( $role, $subrole )

Removes a subrole from a role. If the resulting list of subroles would be empty,
must insert C<'base'>.

=cut

sub setup_from_database {
    my ($proto, $database, $namespace) = @_;

    croak( 'No database' ) unless $database;

    my $authz = $proto->setup_hierarchy( $database->get_roles_data, $namespace );

    # store away as class data
    $authz->_database( $database );

    return $authz;
}

# these methods all return true on success
sub get_roles_data { shift->_database->get_roles_data( @_ ) }

sub remove_role {
    my ($proto) = @_;

    $proto->_database->remove_role( @_ );

    $proto->__reload;
}

sub remove_subrole {
    my ($proto) = @_;

    $proto->_database->remove_subrole( @_ );

    $proto->__reload;
}

# These methods look for potential recursion and return false if they find it.
# If the potential child/subrole can/isa parent/role, then they can not be
# put into the parent/child relationship specified, and the operations must
# abort.

# If the operation is OK, it proceeds and returns a true value on success.

sub move_role {
    my ($proto, $role, $to) = @_;

    croak( 'No destination role in move_role' ) unless $to;

    my @parents;
    foreach my $rl ( $proto->list_roles ) {
        my %subrls = map { $_ => 1 } $proto->role( $rl )->list_roles;
        push( @parents, $rl ) if $subrls{ $role };
    }

    unless ( @parents ) {
        croak( "Couldn't find parent(s) of $role" );
        return;
    }

    my $to_role = $proto->role( $to );

    foreach my $p ( @parents ) {
        return if $to_role->can( $p );
    }

    # OK, let's do it
    $proto->_database->move_role( $role, $to );

    $proto->__reload;
}

# $new_role wants to join $children as subrole of $parent
sub add_role {
    my ($proto, $new_role, $parent, $children) = @_;

    $children ||= 'base';
    my @children = ref( $children ) ? @$children : ( $children );

    # children must exist
    my %all_roles = map { $_ => 1 } $proto->list_roles;
    foreach my $child ( @children ) {
        return unless $all_roles{ $child };
    }

    # and none CAN parent
    foreach my $child ( @children ) {
        return if $proto->role( $child )->can( $parent );
    }

    # OK, let's do it
    $proto->_database->add_role( $new_role, $parent, [ @children ] );

    $proto->__reload;
}

sub add_subrole {
    my ($proto, $role, $subrole) = @_;

    return if $proto->role( $subrole )->can( $role );

    # OK, let's do it
    $proto->_database->add_subrole ( $role, $subrole );

    $proto->__reload;
}

# attempt to load any changes back into the symbol table
sub __reload {
    my ($proto) = @_;

    # delete_package will delete these
    my $namespace = $proto->__namespace;
    my $database  = $proto->_database;

    # Remove the current hierarchy from the symbol table. But not if there's
    # no namespace, because then we would lose Tree::Authz itself
    Symbol::delete_package( ref( $proto ) || $proto ) if $namespace;

    # $proto has namespace already in its name, but has been removed from
    # the symbol table, so have to use __PACKAGE__, which breaks
    # subclassability
    __PACKAGE__->setup_from_database( $database, $namespace );
}

=back

=head2 Adding authorizations

=over

=item setup_permissions_on_role( $role_name, $cando )

Class method version of C<Tree::Authz::Role::setup_permissions>.

=item setup_permissions_on_group( $group_name, $cando )

DEPRECATED.

Use C<setup_permissions_on_role> instead.

=cut

sub setup_permissions_on_role {
    my ($class, $role, $cando) = @_;

    croak( 'Parameter(s) missing' )   unless $cando;
    croak( 'Not an instance method' ) if ref( $class );

    my $role_class = "${class}::Role::$role";

    $role_class->_setup_perms( $cando );
}

sub setup_permissions_on_group {
    carp "'setup_permissions_on_group' is deprecated - use 'setup_permissions_on_role' instead";
    goto &setup_permissions_on_role;
}

=item setup_abilities_on_role( $role_name, %code )

Class method version of C<Tree::Authz::Role::setup_abilities>.

=item setup_abilities_on_group( $group_name, %code )

DEPRECATED.

Use C<setup_abilities_on_role> instead.

=cut

sub setup_abilities_on_role {
    my ($class, $role, %code) = @_;

    croak( 'Not an instance method' ) if ref( $class );
    croak( 'Nothing to set up' )      unless %code;

    my $group_class = "${class}::Role::$role";

    $group_class->_setup_abil( %code );
}

sub setup_abilities_on_group {
    carp "'setup_abilities_on_group' is deprecated - use 'setup_abilities_on_role' instead";
    goto &setup_abilities_on_role;
}

=item setup_plugins_on_role( $role_name, $plugins )

Class method version of C<Tree::Authz::Role::setup_plugins>.

=item setup_plugins_on_group( $group_name, $plugins )

Deprecated version of C<setup_plugins_on_role>.

=cut

sub setup_plugins_on_role {
    my ($class, $role, $plugins) = @_;

    croak( 'Parameter(s) missing' )   unless $plugins;
    croak( 'Not an instance method' ) if ref( $class );

    my $group_class = "${class}::Role::$role";

    $group_class->_setup_plugins( $plugins );
}

sub setup_plugins_on_group {
    carp "'setup_plugins_on_group' is deprecated - use 'setup_plugins_on_role' instead";
    goto &setup_plugins_on_role;
}


=back

=cut

1;

=head1 CHANGES

The deprecation policy is:

1) DEPRECATED methods issue a warning (via C<carp>) and then call the new
method. They will be documented next to the replacement method.

2) OBSOLETE methods will croak. These will be documented in a separate section.

3) Removed methods will be documented in a separate section, in the first
version they no longer exist in.

Main changes in 0.02

    - changed terminology to refer to I<roles> instead of I<groups>. Deprecated
      all methods with I<role> in their name. These methods now issue a
      warning via C<carp>, and will be removed in a future release.
    - added a new class to represent a role - L<Tree::Authz::Role|Tree::Authz::Role>.
      L<Tree::Authz|Tree::Authz> is now a static class (all its methods are
      class methods). The objects it returns from some methods are subclasses
      of L<Tree::Authz::Role|Tree::Authz::Role>.

=head1 TODO

Roles are now represented by their own class. This should make it easier to
add constraints and other RBAC features.

More methods for returning meta information, e.g. immediate subroles of a
role, all subroles of a role, list available actions of a role and its
subroles.

Might be nice to register users with roles.

Make role objects be singletons - not necessary if the only data they carry is
their own name.

Under C<mod_perl>, all setup of hierarchies and permissions must be completed
during server startup, before the startup process forks off Apache children.
It would be nice to have some way of communicating updates to other processes.
Alternatively, you could run the full startup sequence every time you need to
access a Tree::Authz role, but that seems sub-optimal.

=head1 DEPENDENCIES

L<Lingua::EN::Inflect::Number|Lingua::EN::Inflect::Number>,
L<Class::Data::Inheritable|Class::Data::Inheritable>.

Optional - L<Devel::Symdump|Devel::Symdump>.

L<Sub::Override|Sub::Override> for the test suite.

=head1 BUGS

Please report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Authz>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David Baird.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Baird, C<cpan@riverside-cms.co.uk>

=head1 SEE ALSO

L<DBIx::UserDB|DBIx::UserDB>, L<Data::ACL|Data::ACL>.

=cut
