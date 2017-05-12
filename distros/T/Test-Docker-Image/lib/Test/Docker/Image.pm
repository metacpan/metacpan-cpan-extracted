package Test::Docker::Image;

use strict;
use warnings;

use Time::HiRes 'sleep';
use Data::Util ':check';
use Class::Load qw/try_load_class/;

use Test::Docker::Image::Utility qw(docker);
use Class::Accessor::Lite (
    ro => [qw/tag container_ports container_id/],
);

our $VERSION = "0.05";

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $boot_class = delete $args{boot} || 'Test::Docker::Image::Boot';

    try_load_class( $boot_class ) or die "failed to load $boot_class";

    my $image_tag = delete $args{tag};
    die "tag argument is required" unless $image_tag;

    die "container_ports argument must be ArrayRef"
        unless is_array_ref $args{container_ports};

    my @ports = map { ('-p', $_) } @{ $args{container_ports} };

    my $boot         = $boot_class->new;
    my $container_id = $boot->docker_run(\@ports, $image_tag);

    # wait to launch the container
    sleep $args{sleep_sec} || 0.5;

    my $self = bless {
        tag             => $image_tag,
        container_ports => $args{container_ports},
        container_id    => $container_id,
        boot            => $boot,
        boot_class      => $boot_class,
    }, $class;

    return $self;
}

sub port {
    my ($self, $container_port) = @_;
    return $self->{boot}->docker_port($self->container_id, $container_port);
}

sub host {
    $_[0]->{boot}->host;
}

sub DESTROY {
    my $self = shift;
    for my $subcommand ( qw/kill rm/ ) {
        docker($subcommand, $self->container_id);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Docker::Image - It's new $module, this can handle a Docker image for tests.

=head1 SYNOPSIS

    use Test::Docker::Image;

    my $mysql_image_guard = Test::Docker::Image->new(
        container_ports => [3306],
        tag             => 'iwata/centos6-mysql51-q4m-hs',
    );

    my $port = $mysql_image_guard->port(3306);
    my $host = $mysql_image_guard->host;

    `mysql -uroot -h$host -P$port -e 'show plugins'`;
    undef $mysql_image_guard; # destroy a guard object and execute docker kill and rm the container.

=head1 DESCRIPTION

Test::Docker::Image is a module to handle a Docker image.

=head1 METHODS

=head2 C<new>

return an instance of Test::Docker::Image, this instance is used as a guard object.

=over 4

=item C<tag>

This is a required parameter. This specify a tag of Docker image for docker run.

=item C<container_ports>

This is a required parameter. This specify some port numbers that publish a container's port to the host.

=item C<boot>

This is an optional parameter. You set a boot module name.
C<Boot> module must extend Test::Docker::Image::Boot.

=item C<sleep_sec>

This is a optional parameter. Wait seconds after docker run, because you can't access container immediately.

=back

=head2 C<port>

Return a port number, this Docker image use number for port forwarding.

=head2 C<host>

Return an IP address of Docker host.

=head1 LICENSE

Copyright (C) iwata-motonori.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Motonori Iwata E<lt>gootonroi+github@gmail.comE<gt>

=cut

