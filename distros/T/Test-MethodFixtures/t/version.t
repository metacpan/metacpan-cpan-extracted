use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

BEGIN {

    package Mocked::NoVersion;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }

    # NOT YET IMPLEMENTED VERSION CHECKING OF MOCKED CLASSES
    package Mocked::Version;

    our $VERSION = "2";
    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }
}

my $pkg = 'Test::Output';

eval "require $pkg";

plan skip_all => "Can't use $pkg" if $@;

my $result;

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy' } ),
    "got mocker";

# after loading
$Test::MethodFixtures::VERSION = '2.2';
$TestMethodFixtures::Dummy::VERSION = '2.2.2';

ok $mocker->mock('Mocked::NoVersion::foo'), "mocked simple sub";

ok $mocker->mode('record'), "set mode to record";

is Mocked::NoVersion::foo(), 5, "call mocked function";

ok $mocker->mode('playback'), "set mode to playback";

sub tester { $result = Mocked::NoVersion::foo() }

Test::Output::stderr_is( \&tester, '', 'no STDERR' );

is $result, 5, "function result ok";

note "pretend using older version";
$Test::MethodFixtures::VERSION = '1.1';

Test::Output::stderr_like(
    \&tester,
    qr{Data saved with a more recent version \([\d.]+\) of Test::MethodFixtures!},
    'STDERR from Test::MethodFixtures version mismatch'
);

Test::Output::stderr_unlike(
    \&tester,
    qr{Data saved with a more recent version \([\d.]+\) of TestMethodFixtures::Dummy!},
    'No STDERR from storage class version mismatch'
);

is $result, 5, "function result ok";

note "pretend using older version of storage class as well";
$TestMethodFixtures::Dummy::VERSION = '2.2.1';

Test::Output::stderr_like(
    \&tester,
    qr{Data saved with a more recent version \([\d.]+\) of Test::MethodFixtures!},
    'STDERR from Test::MethodFixtures version mismatch'
);

Test::Output::stderr_like(
    \&tester,
    qr{Data saved with a more recent version \([\d.]+\) of TestMethodFixtures::Dummy!},
    'STDERR from storage class version mismatch'
);

is $result, 5, "function result ok";

done_testing();

