use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use MIME::Base64 qw(encode_base64);
use URI ();
use lib 'lib';
use eBay::Client::OpenAPI3;

{
    package Local::FakeUA;
    sub new {
        my ($class, @responses) = @_;
        return bless { responses => [@responses], calls => [] }, $class;
    }
    sub calls { $_[0]->{calls} }
    sub _call {
        my ($self, $method, @args) = @_;
        push @{ $self->{calls} }, [ $method, @args ];
        die "no fake response queued for $method\n" if not @{ $self->{responses} };
        return shift @{ $self->{responses} };
    }
    sub get  { my $self = shift; $self->_call('get',  @_) }
    sub post { my $self = shift; $self->_call('post', @_) }
}

{
    package Local::Client;
    our @ISA = ('eBay::Client::OpenAPI3');
    our $UA;
    our @NEW_UA_OPTS;
    sub _new_ua {
        my ($self, %opts) = @_;
        push @NEW_UA_OPTS, { %opts };
        return $UA;
    }
}

sub response {
    my (%args) = @_;
    return {
        success => ($args{status} >= 200 && $args{status} < 300) ? 1 : q{},
        status  => $args{status},
        reason  => $args{reason} // q{},
        headers => $args{headers} // {},
        content => $args{content} // q{},
    };
}

sub make_config {
    my ($fh, $file) = tempfile();
    print {$fh} <<'EOF_CONFIG';
[eBay]
client_id = client-123
client_secret = secret-456
affiliateCampaignId = 1234567890
affiliateReferenceId = ref-42
EOF_CONFIG
    close $fh;
    return $file;
}

sub new_client_with_ua {
    my ($config, @responses) = @_;
    $Local::Client::UA = Local::FakeUA->new(@responses);
    @Local::Client::NEW_UA_OPTS = ();
    return Local::Client->new(config => $config);
}

my $config = make_config();

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN","token_type":"Application Access Token"}'),
    );

    is($client->oauth2, $client, 'oauth2 returns self for chaining');
    is($client->token->access_token, 'TOKEN', 'oauth2 stores decoded token');
    my $call = $Local::Client::UA->calls->[0];
    is($call->[0], 'post', 'oauth2 uses POST');
    like($call->[1], qr{/identity/v1/oauth2/token\z}, 'oauth2 endpoint unchanged');
    is(
        $call->[2]{headers}{Authorization},
        'Basic ' . encode_base64('client-123:secret-456', q{}),
        'oauth2 Basic authorization unchanged',
    );
    is(
        $call->[2]{content},
        'grant_type=client_credentials&scope=https://api.ebay.com/oauth/api_scope',
        'oauth2 request body unchanged',
    );
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(
            status  => 200,
            content => '{"rateLimits":[{"resources":[{"name":"browse","rates":[{"limit":5000,"count":12,"remaining":4988,"reset":"later","timeWindow":86400}]}]}]}',
        ),
    );
    my $rate = $client->oauth2->rate_limit(api_name => 'browse');
    is($rate->rateLimits->get(0)->resources->get(0)->name, 'browse', 'rate_limit decodes response');
    my $url = $Local::Client::UA->calls->[1][1];
    like($url, qr{/developer/analytics/v1_beta/rate_limit\?}, 'rate endpoint unchanged');
    my %q = URI->new($url)->query_form;
    is($q{api_name}, 'browse', 'rate API query retained');
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(
            status  => 200,
            content => '{"itemId":"v1|12345|0","title":"Example","bidCount":3,"price":{"value":"9.99","currency":"USD"}}',
        ),
    );
    my $item = $client->oauth2->getItem(itemid => 12345);
    is($item->itemId, 'v1|12345|0', 'getItem decodes item response');
    like($Local::Client::UA->calls->[1][1], qr{/buy/browse/v1/item/v1\|12345\|0\z}, 'getItem URL unchanged');
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(status => 200, content => '{"itemId":"v1|99|0"}'),
    );
    is($client->oauth2->get_item(itemid => 99)->itemId, 'v1|99|0', 'get_item is an additive alias');
}

{
    my $next = 'https://api.ebay.com/buy/browse/v1/item_summary/search?offset=2&limit=2&sort=endingSoonest&category_ids=123';
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(
            status  => 200,
            content => '{"total":3,"next":"' . $next . '","itemSummaries":[{"itemId":"v1|1|0","title":"One"}],"warnings":[]}',
        ),
    );
    my $res = $client->oauth2->browse(
        q            => undef,
        category_ids => 123,
        limit        => 2,
        offset       => 0,
        sort         => 'endingSoonest',
    );
    is($res->total, 3, 'browse decodes total');
    is($client->total, 3, 'browse stores total');
    is($client->next, $next, 'browse stores next URL');
    is(scalar($res->itemSummaries->all), 1, 'browse returns item summaries');
    my $url = $Local::Client::UA->calls->[1][1];
    my %q = URI->new($url)->query_form;
    ok(!exists $q{q}, 'undefined browse query omitted');
    is($q{category_ids}, 123, 'category query retained');
    is($q{limit}, 2, 'limit query retained');
    is($q{offset}, 0, 'zero offset retained');
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(
            status  => 429,
            headers => {
                'x-ebay-api-call-limit'        => '5000',
                'x-ebay-api-throttle-limit'    => '100',
                'x-ebay-api-throttle-remaining'=> '0',
            },
            content => '{"errors":[{"longMessage":"slow down"}]}',
        ),
    );
    $client->oauth2;
    my $warnings = q{};
    {
        local $SIG{__WARN__} = sub { $warnings .= join q{}, @_ };
        eval { $client->browse(q => 'x') };
    }
    like($@, qr/slow down \(HTTP Status: 429\)/, 'browse error retains long message and status');
    like($warnings, qr/x-ebay-api-call-limit.*5000/s, 'call-limit header warned');
    like($warnings, qr/x-ebay-api-throttle-limit.*100/s, 'throttle-limit header warned');
    like($warnings, qr/x-ebay-api-throttle-remaining.*0/s, 'throttle remaining warned');
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(status => 500, content => '{"errors":[{"longMessage":"item unhappy"}]}'),
    );
    $client->oauth2;
    eval { $client->getItem(itemid => 77) };
    like($@, qr/item unhappy \(HTTP Status: 500\)/, 'getItem error behavior retained');
}

{
    my $client = new_client_with_ua(
        $config,
        response(status => 200, content => '{"access_token":"TOKEN"}'),
        response(status => 500, content => '{"errors":[{"longMessage":"rate unhappy"}]}'),
    );
    $client->oauth2;
    eval { $client->rate_limit(api_name => 'browse') };
    like($@, qr/rate unhappy \(HTTP Status: 500\)/, 'rate_limit error behavior retained');
}

done_testing;
