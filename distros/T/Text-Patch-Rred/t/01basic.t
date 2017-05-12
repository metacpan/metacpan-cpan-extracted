
# These tests were written by Jakob Bohm in 2006.
#


# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# Text-Patch-Rred.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $pkg;
BEGIN { $pkg = 'Text::Patch::Rred'; }

use Test::More tests => 8;
BEGIN { use_ok($pkg) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $edState;
my $plin;
my $plin2;
my @LinesX;
# The following test data is very incomplete and does not provide full
#    coverage yet, sorry about that.
my @LinesV0 = (



    "Line1\n",
    "Line2\n",
);
my @LinesV1 = (
);
my @LinesV2 = (
);
my @Patch01 = (
    "1,2d\n",
);
my @Patch12 = (
);

ok( ($edState = Text::Patch::Rred::Init(@LinesV0)), "Init() is true");
ok( defined($edState)                                , "state is defined");
is( ref($edState), $pkg       , "state is class ".$pkg);
isa_ok( $edState, $pkg        , "state     ");

@LinesX = Text::Patch::Rred::Result($edState);
is_deeply( [ Text::Patch::Rred::Result($edState) ], \@LinesV0,
   "Result is input before patching");
for $plin (@Patch01)
{
   $plin2 = $plin; chomp $plin2;
   ok( Text::Patch::Rred::Do1($edState, $plin), "applying '".$plin2."'");
}
is_deeply( [ Text::Patch::Rred::Result($edState) ], \@LinesV1,
   "patched from 0 to 1 is V1");
