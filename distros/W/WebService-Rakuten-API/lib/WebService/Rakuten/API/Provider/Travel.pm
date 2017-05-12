package WebService::Rakuten::API::Provider::Travel;
use strict;
use warnings;

use constant BASEHOTELURL => 'https://app.rakuten.co.jp/services/api/Travel/SimpleHotelSearch/20131024?';

use constant HOTELNOURL => 'https://app.rakuten.co.jp/services/api/Travel/HotelDetailSearch/20131024?';

use constant VACANTURL => 'https://app.rakuten.co.jp/services/api/Travel/VacantHotelSearch/20131024?';

use constant GETAREAURL => 'https://app.rakuten.co.jp/services/api/Travel/GetAreaClass/20131024?';

use constant GERHOTELCHAINURL => 'https://app.rakuten.co.jp/services/api/Travel/GetHotelChainList/20131024?';

use constant RANKINGURL => 'https://app.rakuten.co.jp/services/api/Travel/HotelRanking/20131024?';

sub call{
  my ($class,$context,$arg) = @_;
  my $url = URI->new(BASEHOTELURL);
  $url->query_form(applicationId=> $context->appid,format=>'json',largeClassCode => $arg->{largeClassCode},middleClassCode=>$arg->{middleClassCode},smallClassCode=>$arg->{smallClassCode});
 my $res =$context->furl->get($url);
 return $res;
}


1;
