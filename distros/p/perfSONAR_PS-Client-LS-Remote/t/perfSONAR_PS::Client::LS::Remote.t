use Test::More 'no_plan';

use_ok('perfSONAR_PS::Client::LS::Remote');
use perfSONAR_PS::Client::LS::Remote;

my $uri1 = "http://localhost:8080/ls";
my $uri2 = "http://localhost:8085/other/ls";
my %conf1 = ( SERVICE_ACCESSPOINT => "http://localhost:8083/example" );
my %conf2 = ( SERVICE_ACCESSPOINT => "http://localhost:8089/other/example" );

my $ls = perfSONAR_PS::Client::LS::Remote->new($uri1, \%conf1);
ok (defined $ls);
is ($ls->{URI}, $uri1);
is ($ls->{CONF}->{SERVICE_ACCESSPOINT}, $conf1{SERVICE_ACCESSPOINT});

$ls->setURI($uri2);
is ($ls->{URI}, $uri2);

$ls->setConf(\%conf2);
is ($ls->{CONF}->{SERVICE_ACCESSPOINT}, $conf2{SERVICE_ACCESSPOINT});

my %queries = (
	id1 => "some query",
	id2 => "some other query",
);

my ($n, $msg);

($n, $msg) = $ls->query(\%queries);
ok ($n == -1);

my @data = [ "junk1", "junk2" ];
($n, $msg) = $ls->registerStatic(\@data);
ok ($n == -1);

($n, $msg) = $ls->registerDynamic(\@data);
ok ($n == -1);
