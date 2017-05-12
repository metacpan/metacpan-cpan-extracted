package WebService::Simple::Yahoo::JP::API::Auctions;
use base qw(WebService::Simple::Yahoo::JP::API);
our $VERSION = '0.01';
__PACKAGE__->config(
		base_url => 'http://auctions.yahooapis.jp/AuctionWebService/',
		);

sub categorytree { shift->_post('V2/categoryTree', @_); }
sub categoryleaf { shift->_post('V2/categoryLeaf', @_); }
sub sellinglist { shift->_post('V2/sellingList', @_); }
sub search { shift->_post('V2/search', @_); }
sub auctionitem { shift->_post('V2/auctionItem', @_); }
sub bidhistory { shift->_post('V1/BidHistory', @_); }
sub bidhistorydetail { shift->_post('V1/BidHistoryDetail', @_); }
sub showrating { shift->_post('V1/ShowRating', @_); }
sub openwatchlist { shift->_get('V2/openWatchList', @_); }
sub closewatchlist { shift->_get('V2/closeWatchList', @_); }
sub mybidlist { shift->_get('V2/myBidList', @_); }
sub mywonlist { shift->_get('V2/myWonList', @_); }
sub mysellinglist { shift->_get('V1/mySellingList', @_); }
sub mywinnerlist { shift->_get('V1/myWinnerList', @_); }
sub mycloselist { shift->_get('V1/myCloseList', @_); }
sub deletemywonlist { shift->_get('V1/deleteMyWonList', @_); }
sub deletemycloselist { shift->_get('V1/deleteMyCloseList', @_); }
sub myofferlist { shift->_get('V1/myOfferList', @_); }
sub deletemyofferlist { shift->_get('V1/deleteMyOfferList', @_); }
sub reminder { shift->_get('V1/reminder', @_); }
sub deletereminder { shift->_get('V1/deleteReminder', @_); }
sub watchlist { shift->_get('V1/watchList', @_); }
sub deletewatchlist { shift->_get('V1/deleteWatchList', @_); }
sub contentsmatchitem { shift->_post('V1/contentsMatchItem', @_); }
1;
