package WebService::Heartrails::Express::Provider;
use strict;
use warnings;
use utf8;
use Mouse;
use Furl;
use WebService::Heartrails::Express::Provider::Line;
use WebService::Heartrails::Express::Provider::Station;
use WebService::Heartrails::Express::Provider::Near;

has furl => (
  is => 'ro',
 isa => 'Furl', 
);

sub dispatch{
  my($self,$api_name,$arg) = @_;
  my $class = __PACKAGE__.'::'.ucfirst($api_name);
  $class->call($self,$arg);
}

no Mouse;
__PACKAGE__->meta->make_immutable;


1;
