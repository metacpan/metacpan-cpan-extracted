use Test::Spec;
use WWW::Docker;

our $DEFAULT_DOCKER_EXISTS = -S '/var/run/docker.sock';

=head1 Name

www-docker.t - Tests for WWW::Docker and its subclasses

=head1 Description

This test is partly documentation for future readers, it is meant to define the behavior of the docker api client.

Test skipping:
	When this test runs, it will simply ignore testing components of docker unless they are there. Specifically, it will
	only run any tests against the actual Docker API on the system if the default unix socket (/var/run/docker.sock) is
	available to it, and for various items (like Containers and Images) it will skip those tests unless there are items
	of that type already available on the system. The intent here is that while its great if we can actually test against
	the API, its lame to try and make real changes to the system and existing software on the system to satisfy tests.

=cut

describe 'a WWW::Docker client' => sub {
	my $docker;
	################################
	## Basic Object Functionality ##
	################################
	describe 'using the default settings' => sub {
		before each => sub {
			$docker = WWW::Docker->new();
		};
		it 'should use /var/run/docker.sock' => sub {
			is($docker->address(), '/var/run/docker.sock');
		};
	};
	describe 'not using a unix socket' => sub {
		before each => sub {
			$docker = WWW::Docker->new(address => '127.0.0.1');
		};
	};
	###########################################
	## Default Docker Installation Available ##
	###########################################
	SKIP: {
		skip 'a default docker install was not found on this system' unless $DEFAULT_DOCKER_EXISTS;
		describe 'using a unix socket' => sub {
			before each => sub {
				$docker = WWW::Docker->new(address => '/var/run/docker.sock');
			};
			it 'should have a legitimate unix socket as its address' => sub {
				ok(-S $docker->address());
			};
			it 'should be able to get the docker version information' => sub {
				my $version     = $docker->version();
				my $comparisons = {
					GoVersion     => qr/^go[0-9]\.[0-9]\.[0-9]/,
					GitCommit     => qr/[a-z0-9]/,
					Version       => qr/[0-9]\.[0-9]\.[0-9]/,
					BuildTime     => qr/[A-Za-z]+\s+/,
					KernelVersion => qr/.*/,
					Os            => 'linux',
					ApiVersion    => '1.21',
					Arch          => qr/amd64|i386/,
				};
				while (my ($key, $val) = each(%$comparisons)) {
                    cmp_deeply($version->{$key}, re($val));
                }
			};
			###################
			## Docker Images ##
			###################
			SKIP: {
				my $docker  = WWW::Docker->new();
				my ($image) = $docker->images();
				skip 'no images were found on the system to test', 7 unless $image;
				describe 'and given a saved image' => sub {
					before each => sub {
						$docker = WWW::Docker->new();
						($image) = $docker->images();
					};
					it 'should be able to get at least one image' => sub {
						isa_ok($image, 'WWW::Docker::Item::Image');
					};
					it 'should have a number indicating its created time' => sub {
						like($image->Created(), qr(^[0-9]*$));
					};
					it 'should have an id' => sub {
						like($image->Id(), qr/([a-z]|[0-9])/);
					};
					it 'should have a parent id' => sub {
						like($image->ParentId(), qr/([a-z]|[0-9])/);
					};
					it 'should have a list of repo tags' => sub {
						isa_ok($image->RepoTags(), 'ARRAY');
					};
					it 'should have a size in bytes' => sub {
						like($image->Size(), qr(^[0-9]*$));
					};
					it 'should have a virtual size' => sub {
						like($image->Size(), qr(^[0-9]*$));
					};
				};
			}
			#######################
			## Docker Containers ##
			#######################
			SKIP: {
				my $docker      = WWW::Docker->new();
				my ($container) = $docker->containers();
				skip 'no containers were running on the system to test', 8 unless $container;
				describe 'and given a running container' => sub {
					before each => sub {
						$docker = WWW::Docker->new();
						($container) = $docker->containers();
					};
					it 'should be able to get at least one running container' => sub {
						isa_ok($container, 'WWW::Docker::Item::Container');
					};
					it 'should have a command like bash that it was initialized with' => sub {
						is($container->Command(), '/bin/bash');
					};
					it 'should have a number indicating its created time' => sub {
						like($container->Created(), qr(^[0-9]*$));
					};
					it 'should have an id' => sub {
						like($container->Id(), qr/([a-z]|[0-9])/);
					};
					it 'should have an image' => sub {
						like($container->Image(), qr(^[a-z]+:?[0-9latest]));
					};
					it 'should get an array back for its names' => sub {
						isa_ok($container->Names(), 'ARRAY');
					};
					it 'should get at least one name' => sub {
						like($container->Names()->[0], qr(^/));
					};
					it 'should have a valid status' => sub {
						like($container->Status(), qr(^Up));
					};
				};
			}
			###############################
			## Running Docker Containers ##
			###############################
			SKIP: {
				my $docker    = WWW::Docker->new();
				my ($default) = grep {$_->{RepoTags}[0] =~ /centos:latest|ubuntu:latest/} $docker->images();
				skip 'no default centos or ubuntu image available to test running containers', 1 unless $default;
				describe 'and starting a container' => sub {
					before each => sub {
						$docker = WWW::Docker->new();
					};
					it 'should be able to start' => sub {
						my $response = $docker->run($default);
						cmp_deeply($response->{Id}, re(qr/[a-zA-Z0-9]+/));
						is($response->{Warnings}, undef);
					};
				};
			}
		};
	}
};

runtests unless caller;

1;
