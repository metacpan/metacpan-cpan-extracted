package WebService::Simple::Yahoo::JP::API::Map;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => '',
		);

sub static { shift->_get('http://map.olp.yahooapis.jp/OpenLocalPlatform/V1/static', @_); }
sub geocoder { shift->_get('http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder', @_); }
sub reversegeocoder { shift->_get('http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder', @_); }
1;
