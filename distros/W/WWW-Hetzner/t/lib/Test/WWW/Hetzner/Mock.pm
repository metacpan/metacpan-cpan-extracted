package Test::WWW::Hetzner::Mock;

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use Path::Tiny qw(path);
use HTTP::Response;
use WWW::Hetzner::Cloud;
use WWW::Hetzner::Robot;

my $FIXTURES_DIR;

BEGIN {
    # t/lib/Test/WWW/Hetzner/Mock.pm -> t/fixtures
    $FIXTURES_DIR = path(__FILE__)->parent(5)->child('fixtures');
}

sub import {
    my $class = shift;
    my $caller = caller;

    no strict 'refs';
    *{"${caller}::mock_cloud"} = \&mock_cloud;
    *{"${caller}::mock_robot"} = \&mock_robot;
    *{"${caller}::load_fixture"} = \&load_fixture;
}

sub load_fixture {
    my ($name) = @_;
    my $file = $FIXTURES_DIR->child("$name.json");
    return decode_json($file->slurp_utf8);
}

sub mock_cloud {
    my (%routes) = @_;

    my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');

    # Override the _request method
    no warnings 'redefine';
    my $original_request = \&WWW::Hetzner::Cloud::_request;

    *WWW::Hetzner::Cloud::_request = sub {
        my ($self, $method, $path, %opts) = @_;

        my $key = "$method $path";

        # Check for exact match first
        if (exists $routes{$key}) {
            my $handler = $routes{$key};
            if (ref $handler eq 'CODE') {
                return $handler->($method, $path, %opts);
            }
            return $handler;
        }

        # Check for pattern matches
        for my $pattern (keys %routes) {
            if ($path =~ /$pattern/) {
                my $handler = $routes{$pattern};
                if (ref $handler eq 'CODE') {
                    return $handler->($method, $path, %opts);
                }
                return $handler;
            }
        }

        die "No mock route for: $key";
    };

    return $cloud;
}

sub mock_robot {
    my (%routes) = @_;

    my $robot = WWW::Hetzner::Robot->new(
        user     => 'test-user',
        password => 'test-password',
    );

    # Override the _request method
    no warnings 'redefine';

    *WWW::Hetzner::Robot::_request = sub {
        my ($self, $method, $path, %opts) = @_;

        my $key = "$method $path";

        # Check for exact match first
        if (exists $routes{$key}) {
            my $handler = $routes{$key};
            if (ref $handler eq 'CODE') {
                return $handler->($method, $path, %opts);
            }
            return $handler;
        }

        # Check for pattern matches
        for my $pattern (keys %routes) {
            if ($path =~ /$pattern/) {
                my $handler = $routes{$pattern};
                if (ref $handler eq 'CODE') {
                    return $handler->($method, $path, %opts);
                }
                return $handler;
            }
        }

        die "No mock route for: $key";
    };

    return $robot;
}

1;
