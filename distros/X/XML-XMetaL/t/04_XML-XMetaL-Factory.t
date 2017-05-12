# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Factory');
};


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


LOAD_FROM_PATH: {
    my $test = XML::XMetaL::Factory->new();
    my $path = $test->get_xmetal_path().'\Template\Journalist\Article.xml';
    my $xmetal;
    is(eval{ref($xmetal = $test->create_xmetal($path))},
       "Win32::OLE",
       "create_xmetal() using file path");
    diag($@);
}