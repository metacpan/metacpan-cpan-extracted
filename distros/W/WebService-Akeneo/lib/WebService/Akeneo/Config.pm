package WebService::Akeneo::Config;
$WebService::Akeneo::Config::VERSION = '0.001';
use v5.38;
use Object::Pad;

class WebService::Akeneo::Config 0.001;
field $base_url       :param;
field $client_id      :param;
field $client_secret  :param;
field $username       :param;
field $password       :param;
field $scope          :param = '';
field $api_prefix              = '/api/rest/v1';

method base_url      { $base_url }
method client_id     { $client_id }
method client_secret { $client_secret }
method username      { $username }
method password      { $password }
method scope         { $scope }
method api_prefix    { $api_prefix }

1;
