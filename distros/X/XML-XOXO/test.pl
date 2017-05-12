# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::XOXO;
use XML::XOXO::Parser;
$loaded = 1;
print "ok 1\n";


######################### End of black magic.

my $xp = XML::XOXO::Parser->new();
my $xoxo = $xp->parse('<ol class="xoxo"><li>ONE</li><li>TWO</li><li>THREE</li></ol>');
my $root = $xoxo->[0];
my @nodes = $root->match('//li');

if ($nodes[0]->attributes->{'text'} eq 'ONE' &&
   $nodes[1]->attributes->{'text'} eq 'TWO' &&
   $nodes[2]->attributes->{'text'} eq 'THREE') {
    print "ok 2\n";
}

$xoxo = $xp->parse('<ol class="xoxo"><li><dl><dt>test</dt><dd>1</dd><dt>name</dt><dd>Kevin</dd></dl></li></ol>');
my $root = $xoxo->[0];
my @nodes = $root->match('//li');

if ($nodes[0]->attributes->{'test'} == 1 &&
    $nodes[0]->attributes->{'name'} eq 'Kevin') {
    print "ok 3\n";
}

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
