package WebService::Simple::Yahoo::JP::API::Chiebukuro;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://chiebukuro.yahooapis.jp/Chiebukuro/',
		);

sub questionsearch { shift->_get('V1/questionSearch', @_); }
sub categorytree { shift->_get('V1/categoryTree', @_); }
1;
