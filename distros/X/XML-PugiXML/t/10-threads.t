use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl built without ithreads' unless $Config{useithreads};
    plan skip_all => 'threads.pm not available'
        unless eval { require threads; 1 };
}

use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# Every class here wraps a raw C++ pointer. Without CLONE_SKIP, spawning a
# thread would copy the pointer into the child interpreter and give both a
# destructor for it, double-deleting on join. This test crashes the whole
# process rather than failing politely if that protection regresses.

for my $class (qw(XML::PugiXML XML::PugiXML::Node
                  XML::PugiXML::Attr XML::PugiXML::XPath)) {
    ok $class->CLONE_SKIP, "$class sets CLONE_SKIP";
}

my $doc = XML::PugiXML->new;
$doc->load_string('<r a="1"><x/><y/><z/></r>');
my $root  = $doc->root;
my @nodes = $doc->select_nodes('//*');
my $attr  = $root->attr('a');
my $xpath = $doc->compile_xpath('//x');

is $root->name, 'r',   'document set up in the parent thread';
is scalar @nodes, 4,   'node handles held across thread creation';
is $attr->value, '1',  'attribute handle held across thread creation';

# Each thread builds and uses its own document.
my @threads = map {
    my $i = $_;
    threads->create(sub {
        my $d = XML::PugiXML->new;
        $d->load_string("<t$i><c/></t$i>");
        return $d->root->name . ':' . $d->root->child('c')->name;
    });
} 1 .. 4;

is $threads[$_]->join, sprintf('t%d:c', $_ + 1), "thread @{[$_+1]} worked on its own document"
    for 0 .. $#threads;

# Surviving the joins is the actual assertion: a double free would have
# aborted the process before reaching here.
is $root->name, 'r', 'parent document still intact after joins';
like $doc->to_string(''), qr/<r/, 'parent document still serializes';
ok $attr->valid, 'parent attribute handle still valid';
ok $nodes[0]->valid, 'parent node handles still valid';
is scalar(() = $xpath->evaluate_nodes($root)), 1, 'compiled xpath still usable';

done_testing;
