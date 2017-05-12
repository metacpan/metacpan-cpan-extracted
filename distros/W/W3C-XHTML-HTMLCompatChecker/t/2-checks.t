#! /usr/bin/perl -w

print "1..6\n";
use strict;
use W3C::XHTML::HTMLCompatChecker;
print "ok 1\n";
my $checker = W3C::XHTML::HTMLCompatChecker->new();
print "ok 2\n";
my @messages = $checker->check_uri("http://qa-dev.w3.org/wmvs/HEAD/dev/tests/xhtml1-appc-emptycontent.html", any_xhtml=>1);
print "ok 3\n";

if (defined $messages[0]){
    print "ok 4\n";
    if ($messages[0]{severity} eq "Info") {
        print "ok 5\n";
    }
    else {
        print "not ok 5\n";
    }
    if ($messages[0]{line} eq 3) {
        print "ok 6\n";
    }
    else {
        print "not ok 6\n";
    }
}
else {
        print "not ok 4\n";
        print "not ok 5\n";
        print "not ok 6\n";
}

