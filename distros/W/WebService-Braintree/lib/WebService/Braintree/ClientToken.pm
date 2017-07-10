package WebService::Braintree::ClientToken;
$WebService::Braintree::ClientToken::VERSION = '0.91';

use constant DEFAULT_VERSION => "2";

sub generate {
    my ($class, $params) = @_;
    if (!exists $params->{version}) {
        $params->{version} = DEFAULT_VERSION;
    }

    $class->gateway->client_token->generate($params);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

1;
