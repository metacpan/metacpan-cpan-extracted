# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;
use Test::Warn;

use lib qw(lib t/lib);

use WebService::Braintree;

my $config = WebService::Braintree->configuration;

$config->environment("sandbox");
$config->public_key("integration_public_key");
$config->merchant_id("integration_merchant_id");
$config->private_key("integration_private_key");

$config = WebService::Braintree->configuration;

subtest 'server()' => sub {
    my %choices = (
        development => 'localhost',
        integration => 'localhost',
        sandbox     => 'api.sandbox.braintreegateway.com',
        qa          => 'qa-master.braintreegateway.com',
        production  => 'api.braintreegateway.com',
    );

    while (my ($env, $url) = each %choices) {
        $config->environment($env);
        is $config->server, $url, "server() in $env is correct";
    }
};

subtest 'auth_url()' => sub {
    my %choices = (
        development => 'http://auth.venmo.dev:9292',
        integration => 'http://auth.venmo.dev:9292',
        sandbox     => 'https://auth.sandbox.venmo.com',
        qa          => 'https://auth.qa.venmo.com',
        production  => 'https://auth.venmo.com',
    );

    while (my ($env, $url) = each %choices) {
        $config->environment($env);
        is $config->auth_url, $url, "auth_url() in $env is correct";
    }
};

subtest 'ssl_enabled()' => sub {
    my %choices = (
        development => !1,
        integration => !1,
        sandbox     => !!1,
        qa          => !!1,
        production  => !!1,
    );

    while (my ($env, $truth) = each %choices) {
        $config->environment($env);
        if ($truth) {
            ok $config->ssl_enabled, "ssl_enabled() in $env is correct";
        }
        else {
            ok !$config->ssl_enabled, "ssl_enabled() in $env is correct";
        }
    }
};

subtest 'protocol()' => sub {
    my %choices = (
        development => 'http',
        integration => 'http',
        sandbox     => 'https',
        qa          => 'https',
        production  => 'https',
    );

    while (my ($env, $protocol) = each %choices) {
        $config->environment($env);
        is $config->protocol, $protocol, "protocol() in $env is correct";
    }
};

subtest 'port()' => sub {
    for my $env (qw(development integration)) {
        subtest "in $env" => sub {
            $config->environment($env);

            is $config->port, '3000', "Inside $env, port is 3000 by default";

            local $ENV{GATEWAY_PORT} = 9988;
            is $config->port, '9988', "Inside $env, respect GATEWAY_PORT";
        };
    }

    subtest 'outside development' => sub {
        $config->environment('production');
        is $config->port, '443', 'Outside development, port is 443';
    };
};

subtest 'api_version()' => sub {
    is $config->api_version, 4;
};



my @examples = (
    ['sandbox', "https://api.sandbox.braintreegateway.com:443/merchants/integration_merchant_id"],
    ['production', "https://api.braintreegateway.com:443/merchants/integration_merchant_id"],
    ['qa', "https://qa-master.braintreegateway.com:443/merchants/integration_merchant_id"]
);

foreach (@examples) {
    my($environment, $url) = @$_;
    $config->environment($environment);
    is $config->base_merchant_url, $url, "$environment base merchant url";
}

warning_is {
    $config->environment('not_valid')
} 'Assigned invalid value to WebService::Braintree::Configuration::environment',
'Bad environment gives a warning';

$config->environment("integration");
$ENV{'GATEWAY_PORT'} = "8104";
is $config->port, "8104";

done_testing();
