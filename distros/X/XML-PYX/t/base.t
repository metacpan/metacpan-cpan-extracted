print "1..3\n";

use XML::PYX;

my $p = XML::PYX::Parser->new;

print "not " unless $p;
print "ok 1\n";

my $ret = $p->parse('<foo><bar/></foo>');

print "not " unless $ret;
print "ok 2\n";

my $test_res = <<EOT;
(foo
(bar
)bar
)foo
EOT

print "not " unless $ret eq $test_res;
print "ok 3\n";

