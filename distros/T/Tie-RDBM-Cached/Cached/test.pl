# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

my $DRIVER = $ENV{DRIVER};
use constant USER => $ENV{USER};
use constant PASS => $ENV{PASS};
use constant DBNAME => $ENV{DB} || 'test'; 


use Test;
BEGIN { plan tests => 20 };
use DBI;
use Tie::RDBM::Cached;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

if ($DRIVER) {
    print STDERR "Using DBD driver $DRIVER...";
} else {
    die "Found no DBD driver to use.\n";
}

my($dsn) = "dbi:$DRIVER:${\DBNAME}";
print "ok 1\n";

my %h;
test 2,tie %h,'Tie::RDBM::Cached',$dsn,{
                                 create       =>1,
                                 drop         =>0,
                                 table        =>'PData',
                                 'warn'       =>0,
                                 user         =>USER,
                                 password     =>PASS,
                                 cache_size   =>10,
                                 cache_type   =>'HASH',
                                 autocommit   =>1
                                };
%h=();
test 3,!scalar(keys %h);
test 4,$h{'fred'} = 'ethel';
test 5,$h{'fred'} eq 'ethel';
test 6,$h{'ricky'} = 'lucy'; 
test 7,$h{'ricky'} eq 'lucy'; 
test 8,$h{'fred'} = 'lucy'; 
test 9,$h{'fred'} eq 'lucy'; 
test 10,exists($h{'fred'});
test 11,delete $h{'fred'};
test 12,!exists($h{'fred'});
if (tied(%h)->{canfreeze})
{
    local($^W) = 0;  # avoid uninitialized variable warning
    test 13,$h{'fred'}={'name'=>'my name is fred','age'=>34};
    test 14,$h{'fred'}->{'age'} == 34;
} else {
    print STDERR "Skipping tests 13-14 on this platform...";
    print "ok 13 (skipped)\n"; #skip
    print "ok 14 (skipped)\n"; #skip
    $h{'fred'} = 'junk';
}
test 15,join(" ",sort keys %h) eq "fred ricky";
test 16,$h{'george'}=42;
test 17,join(" ",sort keys %h) eq "fred george ricky";
my %i;
test 18,tie %i,'Tie::RDBM::Cached',$dsn,{
                                 create       =>1,
                                 drop         =>1,
                                 table        =>'PData',
                                 'warn'       =>0,
                                 user         =>USER,
                                 password     =>PASS,
                                 cache_size   =>10,
                                 cache_type   =>'HASH',
                                 autocommit   =>0
                                };
test 19,$i{'george'}==42;
test 20,join(" ",sort keys %i) eq "fred george ricky";
