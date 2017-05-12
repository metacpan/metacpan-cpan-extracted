package WebService::Simple::Yahoo::JP::API::Cert;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://cert.yahooapis.jp/MinnaCertWebService/',
		);

sub certlist { shift->_get('V1/certList', @_); }
sub certdetail { shift->_get('V1/certDetail', @_); }
sub certexam { shift->_get('V1/certExam', @_); }
1;
