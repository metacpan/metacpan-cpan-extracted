# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN {
    use lib ('../lib', 'lib');
    use_ok('XML::XMetaL::Registry') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $xmetal_registry;
is(eval{ref($xmetal_registry = XML::XMetaL::Registry->new())},
   "XML::XMetaL::Registry",
   "XML::XMetaL::Registry constructor test");

my @xmetal_versions;
eval{@xmetal_versions = $xmetal_registry->xmetal_versions()};
like($xmetal_versions[0],
   qr/xmetal/i,
   "xmetal_versions() test");
eval {diag($_) foreach $xmetal_registry->xmetal_versions();};

my $xmetal_path;
eval {$xmetal_directory_path = $xmetal_registry->xmetal_directory_path()};
ok(-d $xmetal_directory_path, "xmetal_directory_path() test");
eval {diag($_) foreach $xmetal_registry->xmetal_directory_path();};
