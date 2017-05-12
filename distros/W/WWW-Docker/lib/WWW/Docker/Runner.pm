package WWW::Docker::Runner;
use Moose;
use namespace::autoclean;

with 'WWW::Docker::Client';

use constant DEFAULT_RUN_OPTS => {
	Hostname     => "",
	Domainname   => "",
	User         => "",
	AttachStdin  => JSON::false,
	AttachStdout => JSON::true,
	AttachStderr => JSON::true,
	Tty          => JSON::false,
	OpenStdin    => JSON::false,
	StdinOnce    => JSON::false,
	Env          => ['FOO=bar', 'BAZ=quux'],
	Cmd          => ['date'],
	Entrypoint   => "",
	Image        => "ubuntu",
	Labels       => {
		'com.example.vendor'  => "Acme",
		'com.example.license' => "GPL",
		'com.example.version' => "1.0"
	},
	Mounts => [
		{
			Source      => "/data",
			Destination => "/data",
			Mode        => "ro,Z",
			RW          => JSON::false,
		},
	],
	WorkingDir      => "",
	NetworkDisabled => JSON::false,
	MacAddress      => "12:34:56:78:9a:bc",
	ExposedPorts    => {'22/tcp' => {}},
	StopSignal      => 'SIGTERM',
	HostConfig      => {
		OomKillDisable    => JSON::false,
		PortBindings      => { '22/tcp' => [{ HostPort => '11022' }] },
		PublishAllPorts   => JSON::false,
		Privileged        => JSON::false,
		ReadonlyRootfs    => JSON::false,
		Dns               => ['8.8.8.8'],
		DnsOptions        => [''],
		DnsSearch         => [''],
		ExtraHosts        => undef,
		CapAdd            => ['NET_ADMIN'],
		CapDrop           => ['MKNOD'],
		RestartPolicy     => { Name => '', MaximumRetryCount => 0 },
		NetworkMode       => 'bridge',
		Devices           => [],
		Ulimits           => [{}],
		LogConfig         => { Type => 'json-file', Config => {} },
		SecurityOpt       => [],
		CgroupParent      => '',
		VolumeDriver      => '',
	},
};

# TODO - make either container or image required if one isn't provided
has 'container' => (
	is  => 'ro',
	isa => 'WWW::Docker::Item::Container',
);

has 'image' => (
	is  => 'ro',
	isa => 'WWW::Docker::Item::Image',
);

sub run {
	my ($self, $options) = @_;
	my $json = eval{$self->json->encode(DEFAULT_RUN_OPTS)}; # TODO - not only defaults
	die "JSON ERROR: $@" if $@;
	my $request = HTTP::Request->new('POST', $self->uri('//containers/create'));
	$request->header('Content-Type' => 'application/json');
	$request->content($json);
	return $self->request($request);
}

__PACKAGE__->meta->make_immutable();

1;
