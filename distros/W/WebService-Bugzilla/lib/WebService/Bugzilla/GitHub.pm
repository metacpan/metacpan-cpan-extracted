#!/usr/bin/false
# ABSTRACT: Bugzilla GitHub integration service
# PODNAME: WebService::Bugzilla::GitHub

package WebService::Bugzilla::GitHub 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

sub pull_request {
    my ($self, %params) = @_;
    return $self->client->post($self->_mkuri('github/pull_request'), \%params);
}

sub push_comment {
    my ($self, %params) = @_;
    return $self->client->post($self->_mkuri('github/push_comment'), \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::GitHub - Bugzilla GitHub integration service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    $bz->github->pull_request(
        bug_id     => 12345,
        pull_url   => 'https://github.com/org/repo/pull/42',
    );

    $bz->github->push_comment(
        bug_id  => 12345,
        text    => 'Commit abc123 pushed to main',
    );

=head1 DESCRIPTION

Integration helpers for GitHub-related Bugzilla web-service endpoints.
These endpoints are BMO-specific extensions.

=head1 METHODS

=head2 pull_request

    my $res = $bz->github->pull_request(%params);

Notify Bugzilla about a GitHub pull request.

=head2 push_comment

    my $res = $bz->github->push_comment(%params);

Push a GitHub commit/comment notification to a Bugzilla bug.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
