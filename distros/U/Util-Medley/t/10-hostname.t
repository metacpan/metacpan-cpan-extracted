use Test::More;
use Modern::Perl;
use Util::Medley::Hostname;
use Data::Printer alias => 'pdump';

my $util = Util::Medley::Hostname->new;
ok($util);

###

my ($h, $d) = $util->parseHostname('foobar.example.com');
ok($h eq 'foobar');
ok($d eq 'example.com');

###

my $bool = $util->isFqdn('foobar.example.com');
ok($bool);

$bool = $util->isFqdn('foobar');
ok(!$bool);

###

my $hostname = $util->stripDomain('foobar.example.com');
ok($hostname eq 'foobar');

$hostname = $util->stripDomain('foobar');
ok($hostname eq 'foobar');

$hostname = $util->stripDomain('');
ok($hostname eq '');

done_testing;
