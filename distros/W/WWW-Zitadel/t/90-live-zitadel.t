use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::Zitadel::OIDC;
use WWW::Zitadel::Management;

BEGIN {
    plan skip_all => 'Set ZITADEL_LIVE_TEST=1 to run live tests'
        unless $ENV{ZITADEL_LIVE_TEST};
}

my $issuer = $ENV{ZITADEL_ISSUER}
    or plan skip_all => 'Set ZITADEL_ISSUER for live tests';

my $oidc = WWW::Zitadel::OIDC->new(issuer => $issuer);

my $discovery = $oidc->discovery;
ok $discovery->{jwks_uri}, 'live: discovery includes jwks_uri';
ok $discovery->{token_endpoint}, 'live: discovery includes token_endpoint';

my $jwks = $oidc->jwks;
ok ref($jwks->{keys}) eq 'ARRAY', 'live: jwks has keys array';

if (my $access_token = $ENV{ZITADEL_ACCESS_TOKEN}) {
    my $userinfo = $oidc->userinfo($access_token);
    ok ref($userinfo) eq 'HASH', 'live: userinfo returns hashref';
}
else {
    pass('live: skipping userinfo (set ZITADEL_ACCESS_TOKEN to enable)');
}

if ($ENV{ZITADEL_INTROSPECT_TOKEN} && $ENV{ZITADEL_CLIENT_ID} && $ENV{ZITADEL_CLIENT_SECRET}) {
    my $introspection = $oidc->introspect(
        $ENV{ZITADEL_INTROSPECT_TOKEN},
        client_id     => $ENV{ZITADEL_CLIENT_ID},
        client_secret => $ENV{ZITADEL_CLIENT_SECRET},
    );
    ok ref($introspection) eq 'HASH', 'live: introspection returns hashref';
}
else {
    pass('live: skipping introspection (set token + client credentials to enable)');
}

if (my $pat = $ENV{ZITADEL_PAT}) {
    my $mgmt = WWW::Zitadel::Management->new(
        base_url => $issuer,
        token    => $pat,
    );

    my $org = $mgmt->get_org;
    ok ref($org) eq 'HASH', 'live: management get_org returns hashref';
}
else {
    pass('live: skipping management call (set ZITADEL_PAT to enable)');
}

done_testing;
