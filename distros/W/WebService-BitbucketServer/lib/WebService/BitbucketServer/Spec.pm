package WebService::BitbucketServer::Spec;
# ABSTRACT: Databases for mapping Bitbucket Server REST APIs to code

use warnings;
use strict;

our $VERSION = '0.602'; # VERSION

use Exporter qw(import);
use namespace::clean -except => [qw(import)];

our @EXPORT_OK = qw(api_info documentation_url package_name sub_name);


our $DOCUMENTATION_URL = 'https://developer.atlassian.com/static/rest/bitbucket-server/latest/';

our %API = (
    'access-tokens/1.0'         => {
        id                      => 'access_tokens',
        documentation_filename  => 'bitbucket-access-tokens-rest',
        package                 => 'AccessTokens::V1',
    },
    'api/1.0'                   => {
        id                      => 'core',
        documentation_filename  => 'bitbucket-rest',
        package                 => 'Core::V1',
    },
    'audit/1.0'                 => {
        id                      => 'audit',
        documentation_filename  => 'bitbucket-audit-rest',
        package                 => 'Audit::V1',
    },
    'branch-permissions/2.0'    => {
        id                      => 'ref_restriction',
        documentation_filename  => 'bitbucket-ref-restriction-rest',
        package                 => 'RefRestriction::V2',
    },
    'branch-utils/1.0'          => {
        id                      => 'branch',
        documentation_filename  => 'bitbucket-branch-rest',
        package                 => 'Branch::V1',
    },
    'build-status/1.0'          => {
        id                      => 'build',
        documentation_filename  => 'bitbucket-build-rest',
        package                 => 'Build::V1',
    },
    'comment-likes/1.0'         => {
        id                      => 'comment_likes',
        documentation_filename  => 'bitbucket-comment-likes-rest',
        package                 => 'CommentLikes::V1',
    },
    'default-reviewers/1.0'     => {
        id                      => 'default_reviewers',
        documentation_filename  => 'bitbucket-default-reviewers-rest',
        package                 => 'DefaultReviewers::V1',
    },
    'git/1.0'                   => {
        id                      => 'git',
        documentation_filename  => 'bitbucket-git-rest',
        package                 => 'Git::V1',
    },
    'gpg/1.0'                   => {
        id                      => 'gpg',
        documentation_filename  => 'bitbucket-gpg-rest',
        package                 => 'GPG::V1',
    },
    'jira/1.0'                  => {
        id                      => 'jira',
        documentation_filename  => 'bitbucket-jira-rest',
        package                 => 'JIRA::V1',
    },
    'ssh/1.0'                  => {
        id                      => 'ssh',
        documentation_filename  => 'bitbucket-ssh-rest',
        package                 => 'SSH::V1',
    },
    'mirroring/1.0'             => {
        id                      => 'mirroring_upstream',
        documentation_filename  => 'bitbucket-mirroring-upstream-rest',
        package                 => 'MirroringUpstream::V1',
    },
    'sync/1.0'                  => {
        id                      => 'repository_ref_sync',
        documentation_filename  => 'bitbucket-repository-ref-sync-rest',
        package                 => 'RepositoryRefSync::V1',
    },
);
$API{'keys/1.0'} = $API{'ssh/1.0'};


sub api_info {
    my $endpoint = shift;

    $endpoint = $endpoint->[0] if ref($endpoint) eq 'ARRAY';

    my $namespace = ref($endpoint) eq 'HASH' ? _endpoint_namespace($endpoint) : $endpoint;

    return $API{$namespace};
}

sub _endpoint_namespace {
    my $endpoint = shift;

    my $path = $endpoint->{path};

    my ($namespace) = $path =~ m!^([^/]+/[^/]+)!;
    return $namespace;
}


sub documentation_url {
    my $endpoint    = shift;
    my $type        = shift || 'html';
    my $version     = shift;

    my $namespace   = ref($endpoint) eq 'HASH' ? _endpoint_namespace($endpoint) : $endpoint;
    my $api_info    = api_info($namespace);
    my $filename    = $api_info && $api_info->{documentation_filename} || $namespace;

    my $url = "${DOCUMENTATION_URL}${filename}.${type}";

    $url =~ s/latest/$version/g if $version;

    return $url
}


sub package_name {
    my $endpoint = shift;

    $endpoint = $endpoint->[0] if ref($endpoint) eq 'ARRAY';

    my $api_info = api_info($endpoint);
    return $api_info->{package} if $api_info;

    my $path = $endpoint->{path};

    my ($name, $version) = $path =~ m!^([^/]+)/([^/]+)!;

    $name = ucfirst(lc($name));
    $name =~ s/[^A-Za-z0-9]/_/g;
    $name =~ s/_(.)/uc($1)/eg;

    $version =~ s/[^A-Za-z0-9]/_/g;
    $version =~ s/_0$//;

    return "${name}::V${version}";
}


sub sub_name {
    my $endpoint = shift;

    my $api_info    = api_info($endpoint);
    my $key         = join(' ', @{$endpoint}{qw(path method)});
    my $sub_name    = $endpoint->{id};

    if ($api_info) {
        our %SUBMAP;

        if (!defined $SUBMAP{$api_info->{id}}) {
            require File::ShareDir;
            my $filepath = eval { File::ShareDir::module_file(__PACKAGE__, "submap_$api_info->{id}.pl") };
            if ($filepath) {
                my $subs = do $filepath;
                $SUBMAP{$api_info->{id}} = $subs;
            }
        }

        $sub_name = $SUBMAP{$api_info->{id}}{$key} if defined $SUBMAP{$api_info->{id}}{$key};
    }

    # make it look perly
    $sub_name =~ s/([A-Z])/'_'.lc($1)/eg;

    return $sub_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::BitbucketServer::Spec - Databases for mapping Bitbucket Server REST APIs to code

=head1 VERSION

version 0.602

=head1 FUNCTIONS

=head2 api_info

    $info = api_info($namespace);
    $info = api_info(\%endpoint);

=head2 documentation_url

    $url = documentation_url(\%endpoint);
    $url = documentation_url(\%endpoint, $type);
    $url = documentation_url(\%endpoint, $type, $version);

Get a URL to the Bitbucket Server API documentation for an endpoint. Type can be "html" (default) or
"wadl". Version can be "latest" (default) or a version number like "4.13.0".

=head2 package_name

    $name = package_name(\%endpoint);

Get the name of a package representing an API.

=head2 sub_name

    $name = sub_name(\%endpoint);

Get the name of a subroutine representing an endpoint.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/WebService-BitbucketServer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
