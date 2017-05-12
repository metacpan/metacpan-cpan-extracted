#! perl

use VMS::FileUtils::SafeName qw(:all);

print "1..",255+12,"\n";
print "ok 1\n";
$x = safename('abc.def.ghi');
print "not " if $x ne 'ABC.DEF$5NGHI';
print "ok 2\n";
$x = safename('abc.def.ghi',1);
print "not " if $x ne 'ABC$5NDEF$5NGHI';
print "ok 3\n";
$x = safename('abc.def.ghi',0);
print "not " if $x ne 'ABC.DEF$5NGHI';
print "ok 4\n";
$x = safename('abcDEFghi');
print "not " if $x ne 'ABC$DEF$GHI';
print "ok 5\n";

$x = safepath('ab.cd/ef.gh');
print "not " if $x ne 'AB$5NCD/EF.GH';
print "ok 6\n";

$x = safepath('/ab.cd/ef.gh');
print "not " if $x ne '/AB$5NCD/EF.GH';
print "ok 7\n";
$x = safepath('/ab.cd/ef.gh',1);
print "not " if $x ne '/AB$5NCD/EF$5NGH';
print "ok 8\n";
$x = safepath('/ab.cd/ef.gh',0);
print "not " if $x ne '/AB$5NCD/EF.GH';
print "ok 9\n";
$x = safepath('/ab.cd/ef.gh/');
print "not " if $x ne '/AB$5NCD/EF$5NGH/';
print "ok 10\n";
$x = unsafepath('/AB$5NCD/EF$5NGH/');
print "not " if $x ne '/ab.cd/ef.gh/';
print "ok 11\n";


for ($j = 0; $j < 256; $j++) {
    $unix = 'abc'.chr($j).'XYZ';
    $x = safename($unix);
    $y = unsafename($x);
    print "not " if ($unix ne $y) || !testok($x) || exists($namestore{$x});
    $namestore{$x}=1;
    print "ok ",$j+12,"\n";
}



#
#
#   vms filenames  [A-Z0-9\-\$\_]

sub testok {
    my ($s) = @_;

    my ($okchr) = '[A-Z0-9\-\_\$]';     ## ok chars for VMS filename

    if ($s =~ /^$okchr*(\.$okchr*)?/i) {
        return 1;
    } else {
        return 0;
    }
}

