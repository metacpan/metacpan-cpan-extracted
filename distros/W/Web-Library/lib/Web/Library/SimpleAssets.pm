package Web::Library::SimpleAssets;
use Moose::Role;
requires qw(version_map);

sub version_map_look_up {
    my ($self, $map, $version, $type) = @_;
    my $submap = $map->{$version} // $map->{default};
    @{ $submap->{$type} };
}

sub css_assets_for {
    my ($self, $version) = @_;
    $self->version_map_look_up($self->version_map, $version, 'css');
}

sub javascript_assets_for {
    my ($self, $version) = @_;
    $self->version_map_look_up($self->version_map, $version, 'javascript');
}
1;

=pod

=head1 NAME

Web::Library::SimpleAssets - Moose role for simple assets

=head1 SYNOPSIS

    package Web::Library::Bootstrap;
    use Moose;
    with qw(Web::Library::Provider Web::Library::SimpleAssets);
    
    sub version_map {
        +{  default => {
                css        => ['/css/bootstrap.min.css'],
                javascript => ['/js/bootstrap.min.js'],
            }
        };
    }

=head1 DESCRIPTION

This Moose role is used by distributions that wrap a client-side library. If
you just use L<Web::Library> normally, you do not need it.

