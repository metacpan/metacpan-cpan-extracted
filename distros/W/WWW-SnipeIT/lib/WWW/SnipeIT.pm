package WWW::SnipeIT;
use v5.26;
use Object::Pad;
use WWW::SnipeIT::Hardware;
use WWW::SnipeIT::Users;

our $VERSION = '0.05';

class SnipeIT {
  
  field $endpoint :param = 0;
  field $accessToken :param = 0;

  method snipe () {
    my $header = ['Content-Type' => 'application/json; charset=UTF-8', 'Authorization' => 'Bearer '.$accessToken];
    my $asset = Hardware->new('header'=> $header, 'endpoint' => $endpoint);
    my $users = Users->new('header'=> $header, 'endpoint' => $endpoint);
    
    return {'hardware' => $asset, 'users' => $users};
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::SnipeIT - API Access to Snipe-IT

=head1 SYNOPSIS

  use WWW::SnipeIT;

  my $snipeIT = SnipeIT->new( endpoint => 'http://<mysnipeip>/api/v1/', accessToken => 'mylongapikey');

  my $snipe = $snipeIT->snipe();
  my $result = $snipe->{'hardware'}->getHardwareIDByAssetTag(123);
  say $result;


  # More Examples
  my $updateBody = '{"name":"Fruit Computer","notes":"Apple Computer"}';
  my $searchBody = '{"name":"name","element":"text","field_values":"3Com"}';
  my $assetTag = 123;
  my $hardwareID = 321;
  my $user = "Scott";
  my $fieldName = "";
  my $fieldValue = "3Com";
  my $assetName = "3Com";
  my $searchString = "ChromeBook";
  my $categoryID = 3;
  my $serialNumber = "abc1234";

  warn Dumper($snipe->{'hardware'}->getHardwareIDByAssetTag($assetTag));
  warn Dumper($snipe->{'hardware'}->getHardwareByAssetTag($assetTag));
  warn Dumper($snipe->{'hardware'}->getAssetTagByHardwareID($hardwareID));
  warn Dumper($snipe->{'hardware'}->updateAssetByHardwareID($hardwareID, $updateBody));
  warn Dumper($snipe->{'hardware'}->updateAssetByAssetTag($assetTag, $updateBody));
  warn Dumper($snipe->{'hardware'}->getHardwareByCustomField($fieldName, $user));
  warn Dumper($snipe->{'hardware'}->getHardwareBySerialNumber($serialNumber));


  warn Dumper($snipe->{'hardware'}->getHistoryByHardwareID($hardwareID));
  warn Dumper($snipe->{'hardware'}->getHistoryByAssetTag($assetTag));
  warn Dumper($snipe->{'hardware'}->searchHardware($searchString));

  warn Dumper($snipe->{'hardware'}->getHardwareByCategory($categoryID));

=head1 DESCRIPTION

Snipe-IT ia a asset inventory management system that can be self-hosted or cloud-hosted. It has a REST API and this module is an easy access to it.
[https://snipeitapp.com/](https://snipeitapp.com/)

=head1 AUTHOR

Scott E<lt>scotth@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

