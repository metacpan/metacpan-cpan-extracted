
use Test::More qw(no_plan);
use Test::Exception;

use UltraDNS;

do 't/util.pl';

my $udns = test_connect();
my $rr;


$rr = $udns->GetZoneInfo("none--such--zone.com.");
dies_ok { $udns->commit };
like $@, qr/GetZoneInfo .*failed with .*error 16: Zone not found/;
is $udns->err, 16, 'err should be 16';
like $udns->errstr, qr/^Zone not found/, 'errstr should be set';


my ($zone, $domain) = create_test_zone($udns);

$r = $udns->do( $udns->GetZoneInfo("$domain.") );
is ref $r, 'HASH';
is $r->{name}, $zone;
ok $r->{id};

is $udns->err, 0, 'err should be 0';
is $udns->errstr, '', 'errstr should be reset';

$udns->CreateARecord($zone, "$domain.", '127.0.0.1');
$udns->CreateARecord($zone, "foo.$domain.", '127.0.0.1');
$udns->CreateARecord($zone, "*.$domain.", '127.0.0.1');
$udns->CreateCNAMERecord($zone, "bar.$domain.", "foo.$domain.");
$udns->CreateMXRecord($zone, "*.$domain.", "mail.$domain.", 10);
$udns->commit;

__END__

  if( $zone->{mail_domain} ) {
      UDNS_CreateMXRecord(served_zone => '*.a2homefinder.com', mailserver => 'mail.tigerlead.com', priority => 10);
  ecord( hostname => '*.a2homefinder.com', ip_address => ' 74.86.163.12');

  UDNS_CreateCNAMERecord(alias => 'app', hostname => 'upstream.tigerlead.com');
  UDNS_CreateCNAMERecord(alias => 'ppc-dev', hostname => 'vz2.tigerlead.com');
  UDNS_CreateCNAMERecord(alias => 'ppc-east', hostname => 'east.tiwD' 74.86.163.12');

  UDNS_CreateCNAMERecord(alias => M6ugOrVN7JEZXsjgutViC6wONFvctFUk3GVdYfiQIDAQAB');
  }
  return;
}
