# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Median.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use Test::Warn;
BEGIN { use_ok('Text::Median') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj;
warning_like { $obj = new Text::Median } {carped => qr/Both a module and a method are required./ }, 'new without arguments caught';

warning_like { $obj = new Text::Median(module=>"Non;Existent_Module",method=>"foo") } {carped => qr/not a valid module name/}, 'invalid module name caught';

warning_like { $obj = new Text::Median(module=>"None::Existent::Module",method=>"foo") } { carped => qr/Having a problem using that module/}, 'non existent module loading caut';


#yes, this isn't a string distance calculation.  but it's included with
#the core perl distribution starting in perl 5.8, so new won't fail if we
#use it.
$obj = new Text::Median(module=>"Net::Domain",method=>"domainname");

ok(defined $obj);
