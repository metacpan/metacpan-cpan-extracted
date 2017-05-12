package WWW::Docker;
use Moose;
use namespace::autoclean;
use WWW::Docker::Client;
use WWW::Docker::List;
use WWW::Docker::Runner;
use WWW::Docker::Other;

our $VERSION = 0.03;

####################
## Initialization ##
####################

around BUILDARGS => sub {
    my ($orig, $class) = @_;
    foreach my $method (WWW::Docker::Other::_forwardable()) {
        my $entry = "WWW::Docker::$method";
        unless (defined(&{$entry})) {
            no strict 'refs';
            *{$entry} = sub {return shift->other->$method(@_)};
        }
    }
    return $class->$orig(@_);
};

################
## Attributes ##
################

has 'address' => (
	default => sub {$ENV{DOCKER_HOST} or '/var/run/docker.sock'},
	is      => 'ro',
	isa     => 'Str',
);

#############
## Objects ##
#############

has 'list' => (
	default => sub {WWW::Docker::List->new(address => shift->address())},
	is      => 'rw',
	isa     => 'WWW::Docker::List',
	lazy    => 1,
);

has 'other' => (
    default => sub {WWW::Docker::Other->new(address => shift->address())},
    is      => 'ro',
    isa     => 'WWW::Docker::Other',
    lazy    => 1,
);

#############
## Methods ##
#############

sub run {
    my ($self, $item) = @_;
    my $dockerOptions = ref($_[0]) ? $_[0] : {@_};
    my $runnerOptions = {
        address => $self->address(),
        options => $dockerOptions,
    };
    if (ref($item) eq 'WWW::Docker::Item::Container') {
        $runnerOptions->{container} = $item;
    } elsif (ref($item) eq 'WWW::Docker::Item::Image') {
        $runnerOptions->{image} = $item;
    } else {
        die "container or image required";
    }
    my $runner = WWW::Docker::Runner->new($runnerOptions);
    return $runner->run();
}

####################
## Helper Methods ##
####################

sub containers {return shift->list->containers()}
sub images     {return shift->list->images()}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 Name

WWW::Docker - A Perl 5 Docker API Library

=head1 Description

This package provides a client for Docker's HTTP API which works over IP
or locally over a Unix socket. This package is intended only for Linux systems.

currently supports the following Docker API versions:

docker_remote_api_v1.21 - https://docs.docker.com/engine/reference/api/docker_remote_api_v1.21/

=head1 Synopsis

	my $docker = WWW::Docker->new();
	my $images = $docker->image->list();

	my $runningInstances = $docker->instance->list();

=cut

# ABSTRACT: turns baubles into trinkets
