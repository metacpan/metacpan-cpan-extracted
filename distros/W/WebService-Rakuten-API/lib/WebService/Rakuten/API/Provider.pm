package WebService::Rakuten::API::Provider;
use Mouse;
use WebService::Rakuten::API::Provider::Travel;
use WebService::Rakuten::API::Provider::Ichiba;
use WebService::Rakuten::API::Provider::Books;


has furl => (
  is => 'ro',
 isa =>'Furl',
);

has appid => (
 is =>'rw',
 isa =>'Str',
);

sub dispatch{
 my($self,$api_name,$arg) = @_;
 my $class = __PACKAGE__.'::'.ucfirst($api_name);
 $class->call($self,$arg);
}



1;
