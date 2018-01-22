# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-TFIDF.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Text::TFIDF') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = new Text::TFIDF;
ok(defined $obj && $obj->isa('Text::TFIDF'));
ok($obj->process_files("./t/perlfreebsd.txt","./t/perllinux.txt"));
ok(defined $obj->IDF("perl"));
ok($obj->TF("./t/perlfreebsd.txt","perl"));
ok(defined $obj->TFIDF("./t/perlfreebsd.txt","perl"));
my $ob = new Text::TFIDF(file=>["./t/perlfreebsd.txt","./t/perllinux.txt"]);
ok(defined $ob && $ob->isa('Text::TFIDF'));
ok(defined $obj->TFIDF("./t/perllinux.txt","perl"));
ok(defined $obj->TFIDF("./t/perlfreebsd.txt","perl"));
ok(!defined $obj->TFIDF());
ok(!defined $obj->TFIDF("./t/perlfreebsd.txt"));
