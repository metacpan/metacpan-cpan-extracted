use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Docker::Mock;

# Tests for WWW::Docker::API::Images.
# Read / validation subtests run in mock mode without Docker.
# Write subtests require TESTCONTAINERS_LIVE=1 and WWW_DOCKER_TEST_WRITE=1.

check_live_access();

# ---------------------------------------------------------------------------
# Read tests (always run via mock)
# ---------------------------------------------------------------------------

subtest 'list images' => sub {
    my $docker = test_docker(
        'GET /images/json' => load_fixture('images_list'),
    );

    my $images = $docker->images->list;

    is(ref $images, 'ARRAY', 'returns array');
    if (@$images) {
        isa_ok($images->[0], 'WWW::Docker::Image');
        ok($images->[0]->Id, 'has Id');
    }

    unless (is_live()) {
        is(scalar @$images, 2, 'two images in fixture');

        my $first = $images->[0];
        like($first->Id, qr/^sha256:abc123/, 'image id has sha256 prefix');
        is_deeply($first->RepoTags, ['nginx:latest', 'nginx:1.25'], 'repo tags');
        is($first->Size,       187_654_321, 'image size');
        is($first->Containers, 2,           'container count');
    }
};

# ---------------------------------------------------------------------------

subtest 'inspect image' => sub {
    my $fixture = {
        Id           => 'sha256:abc123',
        RepoTags     => ['nginx:latest'],
        Architecture => 'amd64',
        Os           => 'linux',
        Size         => 187_654_321,
        Config       => { Cmd => ['nginx', '-g', 'daemon off;'] },
    };
    my $docker = test_docker(
        'GET /images/nginx:latest/json' => $fixture,
    );

    my $image;
    if (is_live()) {
        my $images = $docker->images->list;
        if (@$images) {
            my $name = $images->[0]->RepoTags
                ? $images->[0]->RepoTags->[0]
                : $images->[0]->Id;
            $image = $docker->images->inspect($name);
        }
        else {
            plan skip_all => 'No images available for inspect test';
            return;
        }
    }
    else {
        $image = $docker->images->inspect('nginx:latest');
    }

    isa_ok($image, 'WWW::Docker::Image');
    ok($image->Id, 'has Id');

    unless (is_live()) {
        is($image->Id,           'sha256:abc123', 'image id');
        is($image->Architecture, 'amd64',         'architecture');
        is($image->Os,           'linux',         'os');
    }
};

# ---------------------------------------------------------------------------

subtest 'image history' => sub {
    my $docker = test_docker(
        'GET /images/nginx:latest/history' => [
            {
                Id        => 'sha256:abc123',
                Created   => 1_705_300_000,
                CreatedBy => '/bin/sh -c #(nop) CMD ["nginx" "-g" "daemon off;"]',
                Size      => 0,
            },
            {
                Id        => 'sha256:def456',
                Created   => 1_705_299_000,
                CreatedBy => '/bin/sh -c apt-get update',
                Size      => 50_000_000,
            },
        ],
    );

    my $history;
    if (is_live()) {
        my $images = $docker->images->list;
        if (@$images) {
            my $name = $images->[0]->RepoTags
                ? $images->[0]->RepoTags->[0]
                : $images->[0]->Id;
            $history = $docker->images->history($name);
        }
        else {
            plan skip_all => 'No images available for history test';
            return;
        }
    }
    else {
        $history = $docker->images->history('nginx:latest');
    }

    is(ref $history, 'ARRAY', 'history is an array');

    unless (is_live()) {
        is(scalar @$history, 2, 'two history entries');
    }
};

# ---------------------------------------------------------------------------

subtest 'search images' => sub {
    my $docker = test_docker(
        'GET /images/search' => [
            {
                name         => 'nginx',
                description  => 'Official nginx image',
                star_count   => 19_000,
                is_official  => 1,
                is_automated => 0,
            },
        ],
    );

    my $results = $docker->images->search('nginx');

    is(ref $results, 'ARRAY', 'search returns array');

    unless (is_live()) {
        is($results->[0]{name}, 'nginx', 'found nginx');
    }
};

# ---------------------------------------------------------------------------
# Write tests (mock always safe; live requires WWW_DOCKER_TEST_WRITE=1)
# ---------------------------------------------------------------------------

subtest 'image build and pull lifecycle' => sub {
    skip_unless_write();

    my $docker = test_docker(
        'POST /build'                  => sub {
            my ($method, $path, %opts) = @_;
            ok(defined $opts{raw_body},              'raw_body present in build request');
            is($opts{content_type}, 'application/x-tar', 'content type is tar');
            return { stream => 'Successfully built abc123def456' };
        },
        'POST /images/create'          => sub { return '' },
        'POST /images/nginx:latest/tag' => undef,
        'DELETE /images/nginx:latest'   => [
            { Untagged => 'nginx:latest' },
            { Deleted  => 'sha256:abc123' },
        ],
    );

    unless (is_live()) {
        my $result = $docker->images->build(
            context    => 'fake-tar-data',
            t          => 'myapp:latest',
            dockerfile => 'Dockerfile',
        );
        ok($result, 'build returned a result');
        like($result->{stream}, qr/Successfully built/, 'build output contains success message');

        $docker->images->pull(fromImage => 'nginx', tag => 'latest');
        pass('pull completed');

        $docker->images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');
        pass('tag completed');

        my $removed = $docker->images->remove('nginx:latest');
        is(ref $removed, 'ARRAY', 'remove returns array of actions');
    }
};

# ---------------------------------------------------------------------------
# Validation tests (always run, no Docker needed)
# ---------------------------------------------------------------------------

subtest 'build requires context' => sub {
    my $docker = test_docker();

    eval { $docker->images->build(t => 'myapp:latest') };
    like($@, qr/Build context required/, 'croak on missing context');
};

subtest 'image name required' => sub {
    my $docker = test_docker();

    eval { $docker->images->inspect(undef) };
    like($@, qr/Image name required/, 'croak on missing name for inspect');

    eval { $docker->images->remove(undef) };
    like($@, qr/Image name required/, 'croak on missing name for remove');
};

done_testing;
