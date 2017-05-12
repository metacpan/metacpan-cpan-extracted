# ABSTRACT: Feature toggles for Perl
package Toggle;
$Toggle::VERSION = '0.003';
use Moo;

has storage => ( is => 'ro', );

has groups => (
    is      => 'rw',
    default => sub {
        {   'all' => sub {1}
        };
    },
);

sub activate {
    my ( $self, $feature ) = @_;

    $self->activate_percentage( $feature, 100 );
}

sub deactivate {
    my ( $self, $feature ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->clear();
        }
    );
}

sub activate_group {
    my ( $self, $feature, $group ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->add_group($group);
        }
    );
}

sub deactivate_group {
    my ( $self, $feature, $group ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->remove_group($group);
        }
    );
}

sub activate_user {
    my ( $self, $feature, $user ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->add_user($user);
        }
    );
}

sub deactivate_user {
    my ( $self, $feature, $user ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->remove_user($user);
        }
    );
}

sub define_group {
    my ( $self, $group, $coderef ) = @_;

    $self->groups->{$group} = $coderef;
}

sub is_active {
    my ( $self, $feature, $user ) = @_;

    $feature = $self->get($feature);
    return $feature->is_active( $self, $user );
}

sub activate_percentage {
    my ( $self, $feature, $percentage ) = @_;

    $self->_with_feature(
        $feature,
        sub {
            shift->percentage($percentage);
        }
    );
}

sub deactivate_percentage {
    my ( $self, $feature ) = @_;

    $self->activate_percentage( $feature, 0 );
}

sub is_active_in_group {
    my ( $self, $group, $user ) = @_;

    my $g = $self->groups->{$group} || sub {0};
    return $g->($user);
}

sub get {
    my ( $self, $feature ) = @_;

    my $string = $self->storage->get( _key($feature) );

    if ($string) {
        return Toggle::Feature->new( name => $feature, string => $string );
    }
    else {
        my $f = Toggle::Feature->new( name => $feature );
        $self->_save($f);
        return $f;
    }
}

sub add_feature {
    my ( $self, $feature ) = @_;

    my @features = $self->features();
    if ( !grep { $_ eq $feature } @features ) {
        push @features, $feature;
    }

    $self->storage->set( _features_key(), join ",", @features );
}

sub remove_feature {
    my ( $self, $feature ) = @_;

    $self->storage->del( _key($feature) );

    my @features = grep { $_ ne $feature } $self->features();
    $self->storage->set( _features_key(), join ",", @features );
}

sub features {
    my $self = shift;

    return split ',', ( $self->storage->get( _features_key() ) || "" );
}

sub set_variants {
    my ( $self, $feature, $variants ) = @_;

    $feature = $self->get($feature);

    $feature->variants($variants);

    $self->_save($feature);
}

sub variant {
    my ( $self, $feature, $user ) = @_;

    return $self->get($feature)->variant($user);
}

sub _key {
    my $name = shift;
    return "feature:$name";
}

sub _features_key {
    return "feature:__features__";
}

sub _with_feature {
    my ( $self, $feature, $coderef ) = @_;

    my $f = $self->get($feature);
    $coderef->($f);
    $self->_save($f);
}

sub _save {
    my ( $self, $feature ) = @_;

    $self->storage->set( _key( $feature->name ), $feature->serialize() );
    $self->add_feature( $feature->name );
}

package Toggle::Feature;
$Toggle::Feature::VERSION = '0.003';
use Moo;
use String::CRC32;
use Scalar::Util qw(blessed);

has name       => ( is => 'rw' );
has percentage => ( is => 'rw', default => sub { 0 } );
has users      => ( is => 'rw', default => sub { {} } );
has groups     => ( is => 'rw', default => sub { {} } );
has variants   => ( is => 'rw', default => sub { [] } );

sub BUILDARGS {
    my ( $class, %args ) = @_;

    if ( $args{string} ) {
        my ( $raw_percentage, $raw_users, $raw_groups, $raw_variants )
            = split /\|/, $args{string};

        $args{percentage} = $raw_percentage;
        @{ $args{users} }{ split /,/,  $raw_users }  = ();
        @{ $args{groups} }{ split /,/, $raw_groups } = ();
        @{ $args{variants} } = split /,/, $raw_variants || '';
    }

    return \%args;
}

sub serialize {
    my $self = shift;

    return join '|',
        $self->percentage,
        join( ',', keys %{ $self->users } ),
        join( ',', keys %{ $self->groups } ),
        join( ',', @{ $self->variants } );
}

sub add_user {
    my ( $self, $user ) = @_;

    $self->users->{ _user_id($user) } = ();
}

sub remove_user {
    my ( $self, $user ) = @_;

    delete $self->users->{ _user_id($user) };
}

sub add_group {
    my ( $self, $group ) = @_;

    $self->groups->{$group} = ();
}

sub remove_group {
    my ( $self, $group ) = @_;

    delete $self->groups->{$group};
}

sub clear {
    my $self = shift;

    $self->users(  {} );
    $self->groups( {} );
    $self->percentage(0);
    $self->variants( [] );
}

sub variant {
    my ( $self, $user ) = @_;

    my $percentage      = 0;
    my $user_percentage = crc32( _user_id($user) ) % 100;
    my @variants        = @{ $self->variants };

    for ( my $i = 0; $i < @variants; $i += 2 ) {
        $percentage += $variants[ $i + 1 ];

        return $variants[$i] if $user_percentage < $percentage;
    }

    return '';
}

sub is_active {
    my ( $self, $toggle, $user ) = @_;

    if ( !defined $user ) {
        return $self->percentage == 100;
    }
    else {
        return
               $self->_is_user_in_percentage($user)
            || $self->_is_user_in_active_users($user)
            || $self->_is_user_in_active_group( $user, $toggle );
    }
}

sub _is_user_in_percentage {
    my ( $self, $user ) = @_;

    return crc32( _user_id($user) ) % 100 < $self->percentage;
}

sub _is_user_in_active_users {
    my ( $self, $user ) = @_;

    return exists $self->users->{ _user_id($user) };
}

sub _is_user_in_active_group {
    my ( $self, $user, $toggle ) = @_;

    for my $group ( keys %{ $self->groups } ) {
        return 1 if $toggle->is_active_in_group( $group, $user );
    }

    return;
}

sub _user_id {
    my $user = shift;

    return blessed $user && $user->can('id') ? $user->id : $user;
}

1;
