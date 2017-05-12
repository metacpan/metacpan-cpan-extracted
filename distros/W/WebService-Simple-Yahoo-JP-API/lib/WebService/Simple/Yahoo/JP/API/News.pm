package WebService::Simple::Yahoo::JP::API::News;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://news.yahooapis.jp/NewsWebService/',
		);

sub topics { shift->_get('V2/topics', @_); }
sub heading { shift->_get('V1/heading', @_); }
sub topicslog { shift->_get('V1/topicsLog', @_); }
1;
