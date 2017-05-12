
use ExtUtils::testlib;

use Test::More no_plan;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use vars qw( $sMod );
BEGIN
  {
  $sMod = 'WWW::Ebay::Listing';
  use_ok($sMod);
  use_ok('Date::Manip');
  # Date_Init('TZ=GMT');
  } # end of BEGIN block

my $o1 = new $sMod;
isa_ok($o1, $sMod);
$o1->id('my_id');
ok($o1->id eq 'my_id');
$o1->bidcount(9);
ok($o1->bidcount == 9);
$o1->bidmax(999);
ok($o1->bidmax == 999);
$o1->status(new_from_integer WWW::Ebay::Status(99));
isa_ok($o1->status, 'WWW::Ebay::Status');
my $dateNow = ParseDate('now');
my $dateStart = DateCalc($dateNow, ' - 8 days');
my $epochStart = UnixDate($dateStart, '%s');
$o1->datestart($epochStart);
ok($o1->datestart == $epochStart);
my $dateEnd = DateCalc($dateNow, ' - 1 day');
my $epochEnd = UnixDate($dateEnd, '%s');
$o1->dateend($epochEnd);
ok($o1->dateend == $epochEnd);
my $dateShip = DateCalc($dateNow, ' + 1 day');
my $epochShip = UnixDate($dateShip, '%s');
$o1->dateship($epochShip);
ok($o1->dateship == $epochShip);
$o1->winnerid('my_buyer');
ok($o1->winnerid eq 'my_buyer');
$o1->shipping(99);
ok($o1->shipping == 99);
$o1->title('my_title');
ok($o1->title eq 'my_title');
$o1->description('my_description');
ok($o1->description eq 'my_description');
ok($o1->ended);
$oICE->start;
ok(! eval { $o1->not_a_method(1) });
$oICE->stop;
# Test all the ways of calling new:
$oICE->start;
my $o2 = eval '&'. $sMod .'::new()';
$oICE->stop;
isa_ok($o2, 'FAIL');
$o2 = new $sMod;
isa_ok($o2, $sMod);
my $o3 = $o2->new;
isa_ok($o3, $sMod);

__END__

