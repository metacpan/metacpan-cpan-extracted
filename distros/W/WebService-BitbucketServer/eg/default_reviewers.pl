#!/usr/bin/env perl

=head1 NAME

default_reviewers.pl - List default reviewers for recently accessed repositories

=cut

use warnings FATAL => 'all';
use strict;

use Data::Dumper;
use WebService::BitbucketServer;

my $host = shift or die 'Need server url';
my $user = shift or die 'Need username';
my $pass = shift or die 'Need password';

my $api = WebService::BitbucketServer->new(
    base_url => $host,
    username => $user,
    password => $pass,
);

my $repositories = $api->core->get_repositories_recently_accessed;
print_repositories($repositories);

sub print_repositories {
    my $response = shift;

    do {
        handle_error($response) if $response->error;

        for my $repo_info (@{$response->values}) {
            my $repo_slug   = $repo_info->{slug};
            my $project_key = $repo_info->{project}{key};

            print "$project_key/$repo_slug:\n";

            my $conditions = $api->default_reviewers->get_pull_request_conditions_for_repository(
                project_key     => $project_key,
                repository_slug => $repo_slug,
            );
            print_default_reviewers($conditions);
        }
    } while ($response = $response->next);
}

sub print_default_reviewers {
    my $response = shift;

    do {
        handle_error($response) if $response->error;

        my @conditions = @{$response->values};

        if (!@conditions) {
            print "(none)\n";
        }

        for my $condition_info (@conditions) {
            for my $reviewer_info (@{$condition_info->{reviewers}}) {
                my $name    = $reviewer_info->{displayName};
                my $email   = $reviewer_info->{emailAddress};

                print "-> $name <$email>\n";
            }
        }
    } while ($response = $response->next);
}

sub handle_error {
    my $response = shift;
    my $raw = $response->raw;
    print STDERR "Call failed: $raw->{status} $raw->{reason}\n";
    print STDERR Dumper($response->error);
    exit 1;
}

