use URI;
print "1..2\n";
print URI->new("imaps://foo.com")->host eq 'foo.com' ? 'ok 1' : 'not ok 1';
print "\n";
print URI->new("imaps://foo.com")->secure            ? 'ok 2' : 'not ok 2';
print "\n";
