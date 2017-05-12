package WebService::Simple::Yahoo::JP::API::Dir;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://dir.yahooapis.jp/Category/',
		);

sub category { shift->_get('V1/Category', @_); }
sub directorysearch { shift->_get('V1/directorySearch', @_); }
1;
