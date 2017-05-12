use strict;
use warnings;
use Test::More qw[no_plan];
use MIME::Base64 qw[decode_base64 encode_base64];

BEGIN{ use_ok('Win32::MailboxGUID', qw(ad_to_exch exch_to_ad) ) }

my $encode = 'wqQR+d5CwUKNl6vvd2YGPA==
';
my $mbguid = '{F911A4C2-42DE-42C1-8D97-ABEF7766063C}';
my $result = '\C2\A4\11\F9\DE\42\C1\42\8D\97\AB\EF\77\66\06\3C';

{
  my $data = decode_base64( $encode );
  my $exch = ad_to_exch( $data );
  is( $exch, $mbguid, 'Converted to Exchange GUID' );
  my $adint = exch_to_ad( $exch );
  is( $adint, $result, 'Converted to AD GUID' );
  $adint =~ s/\\//g;
  my $binary = join '', map { chr( hex( $_ ) ) } unpack "(A2)*", $adint;
  is( encode_base64( $binary ), $encode, 'Round tripped okay' );
}

{
  my $data = decode_base64( $encode );
  my $exch = Win32::MailboxGUID->ad_to_exch( $data );
  is( $exch, $mbguid, 'Converted to Exchange GUID' );
  my $adint = Win32::MailboxGUID->exch_to_ad( $exch );
  is( $adint, $result, 'Converted to AD GUID' );
  $adint =~ s/\\//g;
  my $binary = join '', map { chr( hex( $_ ) ) } unpack "(A2)*", $adint;
  is( encode_base64( $binary ), $encode, 'Round tripped okay' );
}
