# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use HB;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

HB::init();

my $req = HB::req();

#$req->_file("hye");
$req->file("test.hb") || die "can't load test.hb";
$req->name("main")    || die "can't set name";
$req->input("str=okay");

$req->exec();

if ($req->content() ne "It is okay") {
    print "not ";
}

print "ok 2";

HB::shutdown();
