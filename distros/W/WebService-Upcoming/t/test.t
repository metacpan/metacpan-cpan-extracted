# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming test                                                 *
# *                                                                           *
# *****************************************************************************


# Set-up **********************************************************************
use Test;
BEGIN
{
	plan( 'tests' => 6 );
}


# Uses ************************************************************************
use WebService::Upcoming;


# Code ************************************************************************
my $keyy;
my $upco;
my $objc;

die("\n\n\n".
    "\tYou must put your Upcoming API key in the file ./t/upcoming.key\n".
    "\tin order to successfully run these tests!\n\n\n")
 if (!open(FILE,"t/upcoming.key"));
chomp($keyy = <FILE>);
close(FILE);
die("\n\n\n".
    "\tThe first line of ./t/upcoming.key doesn't look like an Upcoming\n".
    "\tAPI key!\n\n\n") if ($keyy !~ /^[a-z0-9]{10}$/);
$upco = WebService::Upcoming->new($keyy);

$objc = $upco->call('event.getInfo',{ 'event_id' => 1 });
ok(defined($objc));                                          # No error?
ok($objc->[0]->id() == 1);                                   # Right event?
ok($objc->[0]->name() eq 'Tori Amos, Ben Folds');            # Right name?
ok($objc->[0]->venue_id() == 1);                             # Right venue?

$objc = $upco->call('event.getInfo');
ok($upco->err_text() eq 'Missing valid event_id parameter'); # Missing arg

$objc = $upco->call('imaginary.method');
ok($upco->err_text() =~ /^Unknown Upcoming API method: /);   # Bad method
