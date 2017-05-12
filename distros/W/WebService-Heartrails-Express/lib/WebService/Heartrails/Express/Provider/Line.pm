package WebService::Heartrails::Express::Provider::Line;

use utf8;
use Encode;
use Carp;
sub call{
 my ($self,$class,$arg) = @_;

 my $area       = $arg->{area};
 my $prefecture = $arg->{prefecture};

 unless(defined $area or defined $prefecture){
  croak("area or prefecture is eithder required");
 }
 my $sub_url = do{
  if(not defined $area){
    {method => 'getLines',prefecture => $prefecture};
  }elsif(not defined $prefecture){
    {method => 'getLines',area => $area};
  }else{
    {method => 'getLines',area => $area,prefecture => $prefecture};
  }
 };
 my $content = WebService::Heartrails::Express::Provider::Common::call($class,$sub_url);
 return JSON::decode_json($content)->{response}->{line};
}

1;
