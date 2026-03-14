#!/usr/bin/env perl
use strict;
use warnings;

use JSON::MaybeXS qw(encode_json);
use WWW::Zitadel::Management;

my $base_url = $ENV{ZITADEL_ISSUER}
    or die "Set ZITADEL_ISSUER\n";
my $pat = $ENV{ZITADEL_PAT}
    or die "Set ZITADEL_PAT\n";

my $project_name = $ENV{ZITADEL_PROJECT_NAME} // 'demo-project';
my $app_name     = $ENV{ZITADEL_APP_NAME} // 'demo-web';
my $redirect_uri = $ENV{ZITADEL_REDIRECT_URI}
    // 'http://localhost:3000/auth/callback';

my $mgmt = WWW::Zitadel::Management->new(
    base_url => $base_url,
    token    => $pat,
);

my $project = $mgmt->create_project(name => $project_name);
my $project_id = $project->{id} // $project->{projectId}
    or die "No project id in response\n";

my $app = $mgmt->create_oidc_app(
    $project_id,
    name          => $app_name,
    redirect_uris => [$redirect_uri],
);

my $role = $mgmt->add_project_role(
    $project_id,
    role_key     => 'admin',
    display_name => 'Administrator',
);

print encode_json({
    project => $project,
    app     => $app,
    role    => $role,
}), "\n";
