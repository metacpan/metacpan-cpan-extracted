# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Text::Positional::Ngram') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Text::Positional::Ngram;

##################################################################
# Sub Test 1: check token using an eclectic collection of token  #
# definitions ;)                                                 #
##################################################################

############################
# Subtest 1a: using /\w+/  #
############################

$TESTFILE = "t/TESTING/test-1.txt";
$DESTFILE = "test-1a";

# check if this file exists. if not, quit!  
if (!(-e $TESTFILE)) {
    print "File $TESTFILE does not exist... aborting\n";
    exit; 
}

# input token definition file
$TOKENFILE = "t/TESTING/test-1.sub-1-a.token.txt";

# check if this file exists. if not, quit!  
if (!(-e $TOKENFILE)) {
    print "File $TOKENFILE does not exist... aborting\n";
    exit;
}

# required output file
$TARGETFILE = "t/TESTING/test-1.sub-1-a.reqd";

if (!(-e $TARGETFILE)) {
    print "File $TARGETFILE does not exist... aborting\n";
    exit;
}

# now the test! 
$test1a = Text::Positional::Ngram->new();
ok( defined($test1a), 'test1-a new() works'); # Test2
$test1a->set_destination_file($DESTFILE);
$test1a->set_token_file($TOKENFILE);
$test1a->create_files($TESTFILE);
$test1a->set_marginals(1);
$test1a->get_ngrams();
$test1a->remove_files();

#compare the actual output with the required output
system("sort $DESTFILE > one");
system("sort $TARGETFILE > two");
system("diff one two > differences");

ok( -z "differences",  'Test 1-a OK'); #Test3

system("/bin/rm -f one two differences"); 
system("/bin/rm -f $DESTFILE");
