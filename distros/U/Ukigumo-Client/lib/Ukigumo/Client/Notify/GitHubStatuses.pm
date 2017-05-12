package Ukigumo::Client::Notify::GitHubStatuses;
use strict;
use warnings;
use utf8;
use Mouse;
use JSON qw/encode_json/;
use Ukigumo::Constants;

has 'api_endpoint' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'access_token' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Mouse;

sub send {
    my ($self, $c, $status, $last_status, $report_url, $current_revision, $repository_owner, $repository_name) = @_;

    my $ua = $c->user_agent;
    my $access_token = $self->access_token;
    $ua->default_header('Authorization' => "token $access_token");

    my ($state, $description) = _determine_status_and_description($status);
    if (!$state || !$description) {
        # Nothing to do
        return;
    }

    my $payload = encode_json({
        state       => $state,
        target_url  => $report_url,
        description => $description,
    });

    my $destination = sprintf("%s/repos/%s/%s/statuses/%s", $self->api_endpoint, $repository_owner, $repository_name, $current_revision);
    my $res = $ua->post($destination, Content => $payload);

    if ( $res->is_success ) {
        $c->logger->infof("Set commit status to $current_revision");
    }
    else {
        warn "Cannot set commit status to GitHub (NOTE: please check your OAuth permission)";
    }
}

sub _determine_status_and_description {
    my ($status) = @_;

    my ($state, $description);

    if ($status eq STATUS_SUCCESS) {
        $state       = 'success';
        $description = 'The Ukigumo builds passed';
    }
    elsif ($status eq STATUS_FAIL || $status eq STATUS_TIMEOUT) {
        $state = 'failure';
        $description = 'The Ukigumo builds failed';
    }
    elsif ($status eq STATUS_NA || $status eq STATUS_SKIP) {
        # Nothing to do
        return;
    }
    elsif ($status eq STATUS_PENDING) {
        $state       = 'pending';
        $description = 'The Ukigumo is running!';
    }
    else {
        $state       = 'error';
        $description = 'The Ukigumo builds with errores';
    }

    return ($state, $description);
}

1;
__END__

=head1 NAME

Ukigumo::Client::Notify::GitHubStatuses - Set commit status for GitHub.

=head1 DESCRIPTION

This is a notifier class for Ukigumo, set commit status for GitHub.

=head1 ATTRIBUTES

=over 4

=item api_endpoint

URL of the GitHub API endpoint.

=item access_token

Access token of GitHub OAuth. It must granted C<repo:status>.

=back

=head1 SETTING EXAMPLE

Example of C<.ukigumo.yml>;

    notifications:
      github_statuses:
        - api_endpoint: https://api.github.com
          access_token: __ACCESS_TOKEN__

=head1 SEE ALSO

L<https://developer.github.com/v3/repos/statuses/>

