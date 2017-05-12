package WebService::Simple::Yahoo::JP::API::Shopping;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://shopping.yahooapis.jp/ShoppingWebService/',
		);

sub itemsearch { shift->_get('V1/itemSearch', @_); }
sub categoryranking { shift->_get('V1/categoryRanking', @_); }
sub categorysearch { shift->_get('V1/categorySearch', @_); }
sub itemlookup { shift->_get('V1/itemLookup', @_); }
sub queryranking { shift->_get('V1/queryRanking', @_); }
sub contentmatchitem { shift->_get('V1/contentMatchItem', @_); }
sub contentmatchranking { shift->_get('V1/contentMatchRanking', @_); }
sub getmodule { shift->_get('V1/getModule', @_); }
sub eventsearch { shift->_get('V1/eventSearch', @_); }
sub reviewsearch { shift->_get('V1/reviewSearch', @_); }
sub urlitemmatchsearch { shift->_get('V1/json/urlItemMatchSearch', @_); }
sub urlitemmatchlookup { shift->_get('V1/json/urlItemMatchLookup', @_); }
sub urlitemmatchadd { shift->_get('V1/json/urlItemMatchAdd', @_); }
sub urlitemmatchremove { shift->_get('V1/json/urlItemMatchRemove', @_); }
1;
