package WebService::Akeneo::HTTPError;
$WebService::Akeneo::HTTPError::VERSION = '0.001';
use v5.38;
use Object::Pad;
use Carp 'croak';

class WebService::Akeneo::HTTPError 0.001;

field $code    :param;
field $message :param;
field $body    :param;

method throw {
  croak sprintf("HTTP %s: %s%s", ($code//'?'), ($message//'HTTP error'), $body ? "\n$body" : '');
}

1;
