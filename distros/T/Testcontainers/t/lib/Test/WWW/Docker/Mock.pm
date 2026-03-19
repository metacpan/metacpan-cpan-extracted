package Test::WWW::Docker::Mock;
# Helper module for WWW::Docker tests.
# Provides a lightweight mock of the Docker HTTP transport so tests that verify
# API logic can run without a live Docker daemon.  When the TESTCONTAINERS_LIVE
# environment variable is set (or WWW_DOCKER_TEST_HOST is provided) the real
# Docker daemon is used instead.

use strict;
use warnings;
use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny;
use Carp qw( croak );
use Test::More;

use Exporter 'import';
our @EXPORT = qw(
  test_docker
  load_fixture
  is_live
  can_write
  skip_unless_write
  check_live_access
  register_cleanup
);

# __FILE__ is t/lib/Test/WWW/Docker/Mock.pm; five parents up is t/, then fixtures/
my $FIXTURES_DIR = path(__FILE__)->parent->parent->parent->parent->parent->child('fixtures');

my @_cleanups;

# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

sub load_fixture {
    my ($name) = @_;
    my $file = $FIXTURES_DIR->child("$name.json");
    croak "Fixture not found: $file" unless $file->exists;
    return decode_json($file->slurp_utf8);
}

# is_live() -- true when tests should run against a real Docker daemon.
# Triggered by TESTCONTAINERS_LIVE=1 or a non-empty WWW_DOCKER_TEST_HOST.
sub is_live {
    return !!($ENV{TESTCONTAINERS_LIVE} || $ENV{WWW_DOCKER_TEST_HOST});
}

# can_write() -- true when destructive/write tests are permitted in live mode.
sub can_write {
    return is_live() && !!$ENV{WWW_DOCKER_TEST_WRITE};
}

# skip_unless_write() -- skips unless we are allowed to perform write tests.
# In mock mode write tests always run (they are fully mocked).
sub skip_unless_write {
    if (is_live() && !can_write()) {
        plan skip_all => 'Write tests skipped in live mode (set WWW_DOCKER_TEST_WRITE=1 to enable)';
    }
    return;
}

# check_live_access() -- skips the whole file if live mode is requested but
# the daemon is not reachable.
sub check_live_access {
    return unless is_live();

    my $host = $ENV{WWW_DOCKER_TEST_HOST} || 'unix:///var/run/docker.sock';

    if ($host =~ m{^unix://(.+)$}) {
        unless (-S $1) {
            plan skip_all => "Docker socket $1 not available";
            return;
        }
    }

    eval {
        require WWW::Docker;
        my $docker = WWW::Docker->new(host => $host);
        my $result = $docker->system->ping;
        die "ping failed" unless $result eq 'OK';
    };
    if ($@) {
        plan skip_all => "Docker daemon not reachable: $@";
    }
    return;
}

sub register_cleanup {
    my ($code) = @_;
    push @_cleanups, $code;
    return;
}

# ---------------------------------------------------------------------------
# test_docker(%routes) -- returns either a real WWW::Docker instance (live
# mode) or a lightweight mock that intercepts _request() calls.
# ---------------------------------------------------------------------------

sub test_docker {
    my (%routes) = @_;

    if (is_live()) {
        require WWW::Docker;
        my $host = $ENV{WWW_DOCKER_TEST_HOST} || 'unix:///var/run/docker.sock';
        return WWW::Docker->new(host => $host);
    }

    return _mock_docker(%routes);
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub _mock_docker {
    my (%routes) = @_;

    # Provide a default /version response so WWW::Docker can be constructed.
    unless (grep { /version/ } keys %routes) {
        $routes{'GET /version'} = load_fixture('system_version');
    }

    require WWW::Docker;

    my $docker = WWW::Docker->new(
        host        => 'unix:///var/run/docker.sock',
        api_version => '1.47',
    );

    my $mock_request = sub {
        my ($self, $method, $path, %opts) = @_;

        # Strip API version prefix so routes can be written as /containers/json
        my $clean_path = $path;
        $clean_path =~ s{^/v[\d.]+}{};

        my $key = "$method $clean_path";

        # Exact match
        if (exists $routes{$key}) {
            my $handler = $routes{$key};
            return ref $handler eq 'CODE'
                ? $handler->($method, $clean_path, %opts)
                : $handler;
        }

        # Pattern match (route path treated as regex)
        for my $pattern (keys %routes) {
            my ($route_method, $route_path) = split /\s+/, $pattern, 2;
            next unless $method eq $route_method;
            if ($clean_path =~ m{^$route_path$}) {
                my $handler = $routes{$pattern};
                return ref $handler eq 'CODE'
                    ? $handler->($method, $clean_path, %opts)
                    : $handler;
            }
        }

        croak "No mock route for: $key (available: " . join(', ', sort keys %routes) . ")";
    };

    # Bless into a unique subclass that overrides _request()
    my $mock_pkg = 'WWW::Docker::Mock::' . int(rand(1_000_000));
    {
        no strict 'refs';
        @{"${mock_pkg}::ISA"}    = ('WWW::Docker');
        *{"${mock_pkg}::_request"} = $mock_request;
    }

    bless $docker, $mock_pkg;
    return $docker;
}

sub _run_cleanups {
    for my $cleanup (reverse @_cleanups) {
        eval { $cleanup->() };
        warn "Cleanup failed: $@" if $@;
    }
    @_cleanups = ();
    return;
}

END { _run_cleanups() }

1;

__END__

=head1 NAME

Test::WWW::Docker::Mock - Test helper for WWW::Docker tests

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::WWW::Docker::Mock;

    check_live_access();

    my $docker = test_docker(
        'GET /containers/json' => load_fixture('containers_list'),
    );

    my $containers = $docker->containers->list(all => 1);

=head1 DESCRIPTION

Provides a mock Docker client for unit testing L<WWW::Docker> API modules
without requiring a running Docker daemon.

When C<TESTCONTAINERS_LIVE=1> (or C<WWW_DOCKER_TEST_HOST> is set), tests run
against a real Docker daemon.  Otherwise the mock intercepts C<_request()>
calls and returns pre-configured or fixture-based responses.

Fixtures live in C<t/fixtures/> as JSON files.

=head1 ENVIRONMENT

=over

=item TESTCONTAINERS_LIVE

Set to C<1> to run tests against the local Docker daemon
(C<unix:///var/run/docker.sock>).

=item WWW_DOCKER_TEST_HOST

Override the Docker host URL (e.g. C<tcp://remote:2375>).

=item WWW_DOCKER_TEST_WRITE

Set to C<1> when live to enable write/destructive tests (create, remove, etc.).

=back

=cut
