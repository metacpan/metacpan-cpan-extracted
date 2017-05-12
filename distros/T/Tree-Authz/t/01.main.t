#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 60;
use Test::Exception;

use Tree::Authz;

use strict;
use warnings;

### setup_hierarchy
my $groups = { superuser    => [ qw( spymasters politicians ) ],
               spymasters   => [ qw( spies moles ) ],
               spies        => [ 'informants' ],
               informants   => [ 'base' ],
               moles        => [ 'base' ],
               politicians  => [ 'citizens' ],
               citizens     => [ 'base' ],
               };

my ($SpyLand, $NoNameLand);
lives_ok { $SpyLand = 'Tree::Authz'->setup_hierarchy( $groups, 'SpyLand' ) } 'roles set up' ;
lives_ok { $NoNameLand = Tree::Authz->setup_hierarchy( $groups ) } 'roles set up with no namespace' ;

### group_exists
ok( $SpyLand->role_exists( 'spies' ), 'spies role_exists in SpyLand' );
like( "SpyLand::Tree::Authz", qr/^$SpyLand$/, "got expected class name - $SpyLand" );

ok( $NoNameLand->role_exists( 'spies' ), 'spies role_exists in default namespace' );
like( "Tree::Authz", qr/^$NoNameLand$/, "got expected class name - $NoNameLand" );

### dump_hierarchy
my $tree;
lives_ok { $tree = $SpyLand->dump_hierarchy( 'SpyLand' ) } 'survived call to dump_hierarchy';

my $tree_out = <<TREE;
SpyLand::Tree::Authz::Role::superuser
\tSpyLand::Tree::Authz::Role::spymasters
\t\tSpyLand::Tree::Authz::Role::spies
\t\t\tSpyLand::Tree::Authz::Role::informants
\t\t\t\tSpyLand::Tree::Authz::Role::base
\t\t\t\t\tTree::Authz::Role
\t\tSpyLand::Tree::Authz::Role::moles
\t\t\tSpyLand::Tree::Authz::Role::base
\t\t\t\tTree::Authz::Role
\tSpyLand::Tree::Authz::Role::politicians
\t\tSpyLand::Tree::Authz::Role::citizens
\t\t\tSpyLand::Tree::Authz::Role::base
\t\t\t\tTree::Authz::Role
TREE

$tree_out =~ s/\n$//;

like( $tree, qr/$tree_out/, 'got expected tree for SpyLand namespace' );

my $tree2;
lives_ok { $tree2 = $NoNameLand->dump_hierarchy } 'survived call to dump_hierarchy with no namespace';

my $tree2_out = <<TREE;
Tree::Authz::Role::superuser
\tTree::Authz::Role::spymasters
\t\tTree::Authz::Role::spies
\t\t\tTree::Authz::Role::informants
\t\t\t\tTree::Authz::Role::base
\t\t\t\t\tTree::Authz::Role
\t\tTree::Authz::Role::moles
\t\t\tTree::Authz::Role::base
\t\t\t\tTree::Authz::Role
\tTree::Authz::Role::politicians
\t\tTree::Authz::Role::citizens
\t\t\tTree::Authz::Role::base
\t\t\t\tTree::Authz::Role
TREE

$tree2_out =~ s/\n$//;

like( $tree2, qr/$tree2_out/, 'got expected tree for default namespace' );

### get_group and new
my ($spies, $spies2, $superuser, $base);
lives_ok { $spies = $SpyLand->role( 'spies' ) } 'survived role';
isa_ok( $spies, "SpyLand::Tree::Authz::Role::spies" );
isa_ok( $superuser = $SpyLand->role( 'superuser' ), "SpyLand::Tree::Authz::Role::superuser" );
isa_ok( $base = $SpyLand->role( 'base' ), "SpyLand::Tree::Authz::Role::base" );

### group_exists
ok( $SpyLand->role_exists( 'politicians' ), 'politicians role_exists' );

### group_name
like( $spies->name, qr/^spies$/, 'name' );

my $informants = $SpyLand->role( 'informants' ) || die 'Unexpected failure';

### default can
ok( !    $spies->can( 'jhsfuif' ), 'spies cannot jhsfuif' );
ok(  $superuser->can( 'jhsfuif' ), 'but superuser can jhsfuif' );
ok( !     $base->can( 'can' ),     'and base can\'t even can!' );
ok(      $spies->can( 'spies' ),   'spies can spies' );
ok(      $spies->can( 'spy' ),     'spies can spy' );
ok( $informants->can( 'informants' ), 'informants can informants' );
ok( $informants->can( 'informant' ),  'informants can informant' );
ok(      $spies->can( 'informant' ), 'spies can informant' );
ok( $SpyLand->role( 'spymasters' )->can( 'informant' ), 'spymasters can informant' );
ok( $SpyLand->role( 'spymasters' )->can( 'spies' ), 'spymasters can spies' );
ok( $SpyLand->role( 'spymasters' )->can( 'moles' ), 'spymasters can moles' );

my $spies_can = [ qw( read_secrets wear_disguise ) ];
my $informants_can = 'tell_tales';
my $base_can = 'breathe';

### setup_permissions
lives_ok {
    $spies->setup_permissions( $spies_can );
    $base->setup_permissions( $base_can );
    $informants->setup_permissions( $informants_can );
    } 'setup groups perms';

# can
ok( $spies->can( 'read_secrets' ), 'spies can read_secrets' );
ok( $spies->can( 'wear_disguise' ), 'spies can wear_disguise' );
ok( $spies->can( 'tell_tales' ), 'spies can tell_tales' );
ok( $informants->can( 'tell_tales' ), 'informants can tell_tales' );
ok( ! $informants->can( 'read_secrets' ), 'informants can NOT read_secrets' );
ok( ! $base->can( 'breathe' ), 'base can not even breathe!' );
ok( $spies->can( 'breathe' ) && $informants->can( 'breathe' ), 'but spies and informants can breathe' );

### setup_abilities
my %spies_able = ( encode_text => sub { my @chars = split( '', $_[1] );
                                        join( '', reverse @chars );
                                        },
                 );

lives_ok { $spies->setup_abilities( %spies_able ) } 'survived setup_abilities';
like( $spies->encode_text( 'abc' ), qr/^cba$/, 'spies can encode text' );
dies_ok { $informants->encode_text( 'abc' ) } 'informants die if they try to encode text!';

my $spymasters = $SpyLand->role( 'spymasters' ) || die 'Unexpected failure';
like( $spymasters->encode_text( 'abc' ), qr/^cba$/, 'spymasters can encode text too' );

my $politicians = $SpyLand->role( 'politicians' ) || die 'Unexpected failure';
dies_ok { $politicians->encode_text( 'abc' ) } 'politicians also die if they try to encode text!';

ok( $superuser->encode_text( 'abc' ) eq 'cba', 'superuser can encode text too' );

### setup_plugins
{
    package Spies::Extras;

    sub assassinate {
        my ($self, $target) = @_;
        return "DEAD $target";
    }

    sub escape {}
}

lives_ok { $spies->setup_plugins( 'Spies::Extras' ) } 'survived setup_plugins';

ok( $spymasters->can( 'assassinate' ), 'spymasters can do the method added to spies' );
ok( $spies->can( 'assassinate' ), 'as can spies' );
ok( ! $politicians->can( 'assassinate' ), 'but politicians can\'t' );
like( $spies->assassinate( 'victim' ), qr/^DEAD victim$/, 'added method works for spies' );
like( $spymasters->assassinate( 'other victim' ), qr/^DEAD other victim$/, 'added method works for spymasters' );
dies_ok { $politicians->assassinate( 'victim' ) } 'but politicians die';

### subrole_exists
SKIP: {
    skip '- subrole_exists not implemented', 3;

    ok( $SpyLand->subrole_exists( 'informants', 'spies' ), 'informants are a subgroup of spies' );
    ok( ! $SpyLand->subrole_exists( 'moles', 'spies' ), 'moles are not a subgroup of spies' );
    ok( $SpyLand->subrole_exists( 'informants', 'spymasters' ), 'informants are a deep subgroup of $spymasters' );

}

### setup_permissions_on_role
my $cando = [ qw( shoot_gun fly_helicopter ) ];
dies_ok  { $spies->setup_permissions_on_role( 'spies', $cando ) } "can't setup_permissions_on_role through $spies";
lives_ok { $SpyLand->setup_permissions_on_role( 'spies', $cando ) } "can   setup_permissions_on_role through $SpyLand";
ok( $spies->can( 'fly_helicopter' ), 'permission granted' );

### setup_abilities_on_role
my %able = ( math => sub { 2 * 2 } );
dies_ok  { $spies->setup_abilities_on_role( 'spies', %able ) } "can't setup_abilities_on_role through $spies";
lives_ok { $SpyLand->setup_abilities_on_role( 'spies', %able ) } "can   setup_abilities_on_role through $SpyLand";
like( $spies->math, qr/^4$/, 'spies have new ability' );

### setup_plugins_on_role
{
    package My::Spies;

    sub wear_silly_disguise {}

    sub read_dirty_secret {
        my ($self, $file) = @_;
        open( SECRET, $file );
        local $/;
        <SECRET>;
    }
}

dies_ok  { $spies->setup_plugins_on_role( 'spies', 'My::Spies' ) } "can't setup_plugins_on_role through $spies";
lives_ok { $SpyLand->setup_plugins_on_role( 'spies', 'My::Spies' ) } "can   setup_plugins_on_role through $SpyLand";
ok( $spies->can( 'wear_silly_disguise' ), 'got new ability' );

__END__

### persistence methods - experimental

{
    package My::Persist;
    use Carp;

    sub new {
        my $roles = { superuser    => [ 'admin' ],
                      admin        => [ qw( siteadmin useradmin ) ],
                      siteadmin    => [ qw( fooadmin editor ) ],
                      fooadmin     => [ qw( useradmin editor ) ],
                      useradmin    => [ 'base' ],
                      editor       => [ 'base' ],
                      };
        my $self = {};
        $self->{DATA} = $roles;
        bless $self, 'My::Persist';
    }

    sub get_roles_data { $_[0]->{DATA} }

    sub add_role {
        my ($self, $new_role, $parent, $children) = @_;

        my $roles = $self->get_roles_data;

        push @{ $roles->{ $parent } }, $new_role;

    }

    sub remove_role {
        my ($self, $role) = @_;

        # retrieve the role's isa_list
        my @subroles = $self->_get_subroles( $role );

        # remove the role from the isa_lists of any parent roles
        $self->remove_subrole( $_, $role ) for $self->_list_roles;

        delete $self->{DATA}->{ $role };

        return @subroles;
    }

    sub move_role {
        my ($self, $role, $to) = @_;

        my @children = $self->remove_role( $role );

        # returns 1 on success
        $self->add_role( $role, $to, [ @children ] );
    }

    sub add_subrole {
        my ($self, $role, $subrole) = @_;

        unless ( $subrole ) {
            carp( "No subrole to add to $role" );
            return;
        }

        # returns true on success
        $self->_set_subroles( $role,
                              $self->_get_subroles( $role ), $subrole
                              );
    }

    sub remove_subrole {
        my ($self, $role, $subrole) = @_;

        my %subroles = map { $_ => 1 } $self->_get_subroles( $role );

        return unless delete $subroles{ $subrole };

        my @subroles = keys %subroles || ( 'base' );

        # returns true on success
        $self->_set_subroles( $role, @subroles );
    }

    sub _get_subroles {
        my ($self, $role) = @_;

        @{ $self->{DATA}->{ $role } };
    }

    sub _set_subroles {
        my ($self, $role, @subroles) = @_;

        # only inherit from 'base' if you have no other option
        if ( @subroles > 1 ) {
            @subroles = grep { ! /^base$/ } @subroles;
        }

        # prevent cheating
        @subroles = grep { ! /^superuser$/ } @subroles;

        unless ( @subroles ) {
            carp( "No subroles to set for $role" );
            return;
        }

        $self->{DATA}->{ $role } = [ @subroles ];
        return 1;
    }

    sub _list_roles { keys %{ $_[0]->{DATA} } }
}

my $db = My::Persist->new;

my $siteauthz;

lives_ok { $siteauthz = Tree::Authz->setup_from_database( $db, 'Site' ) }
    'survived setup_from_database';
####
####    print "siteadmin subroles: ", join( ', ', $siteauthz->role( 'siteadmin' )->list_roles ), "\n";
    lives_ok { $siteauthz->move_role( 'admin', 'siteadmin' ) } 'moved admin to under siteadmin';
####    print "siteadmin subroles: ", join( ', ', $siteauthz->role( 'siteadmin' )->list_roles ), "\n";

