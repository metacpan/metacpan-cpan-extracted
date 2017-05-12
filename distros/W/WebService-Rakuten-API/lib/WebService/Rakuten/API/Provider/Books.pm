package WebService::Rakuten::API::Provider::Books;
use strict;
use warnings;

use constant BASEBOOKTOTALSURL => 'https://app.rakuten.co.jp/services/api/BooksTotal/Search/20130522?';

use constant BASEBOOKSSEARCHURL => 'https://app.rakuten.co.jp/services/api/BooksBook/Search/20130522?';

use constant BASECDURL => 'https://app.rakuten.co.jp/services/api/BooksCD/Search/20130522?';

use constant BASEDVDURL => 'https://app.rakuten.co.jp/services/api/BooksDVD/Search/20130522?';

use constant BASEFOREIGNURL => 'https://app.rakuten.co.jp/services/api/BooksForeignBook/Search/20130522?';

use constant BASEMAGAZINEURL => 'https://app.rakuten.co.jp/services/api/BooksMagazine/Search/20130522?';

use constant BASEGAMEURL => 'https://app.rakuten.co.jp/services/api/BooksGame/Search/20130522?';

use constant BASESOFTURL => 'https://app.rakuten.co.jp/services/api/BooksSoftware/Search/20130522?';

use constant BASEGENREURL => 'https://app.rakuten.co.jp/services/api/BooksGenre/Search/20121128?';

sub call{
 my($class,$context,$arg) = @_;
 my $url = URI->new(BASEBOOKTOTALSURL);
 $url->query_form(applicationId => $context->appid,format=> $arg->{format},keyword=>$arg->{keyword});
 my $res = $context->furl->get($url);
}


1;
