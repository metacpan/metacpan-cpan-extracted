package WebService::Mattermost::V4::API::Object::Plugins;

use Moo;
use Types::Standard qw(ArrayRef Maybe);

use WebService::Mattermost::V4::API::Object::Plugin;

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has [ qw(active inactive) ] => (is => 'ro', isa => Maybe[ArrayRef], lazy => 1, builder => 1);

################################################################################

sub _map_plugin_objs {
    my $self = shift;
    my $type = shift;

    return [
        map {
            my $args = $_;

            $args->{base_url}   = $self->base_url;
            $args->{auth_token} = $self->auth_token;
            $args->{raw_data}   = {};

            WebService::Mattermost::V4::API::Object::Plugin->new($_)
        } @{$self->raw_data->{$type}}
    ];
}

################################################################################

sub _build_active {
    my $self = shift;

    return unless $self->raw_data->{active};
    return $self->_map_plugin_objs('active');
}

sub _build_inactive {
    my $self = shift;

    return unless $self->raw_data->{inactive};
    return $self->_map_plugin_objs('inactive');
}

################################################################################

1;

