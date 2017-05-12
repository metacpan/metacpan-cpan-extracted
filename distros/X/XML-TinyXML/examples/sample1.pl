#!/usr/bin/perl
use XML::TinyXML;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $hash = { 
    a => 'b' , 
    c => 'd', 
    hash => { 
        key1 => 'value1',
        key2 => 'value2' 
    }, 
    array => [ 
        "arrayval1", 
        { subhashkey => 'subhashvalue' }, 
        [  # XXX - folded arrays will be flattened by actual implementation
            { nome1 => 'subarray1' } , 
            { nome2 => 'subarray2' , 'nome2.5' => 'dfsdf'}, 
            { nested => { nested2_1 => 'nestedvalue', nested2_2 => 'nestedvalue2' } },
            "subarrayval1", 
            "subarrayval2" 
        ]
    ]
};


my $txml = XML::TinyXML->new($hash);
printf("%s \n", $txml->dump);

my $testnode = $txml->getNode("/txml/a");
print "node a _ ".$testnode->value . " (".$testnode->name .") \n";

printf("%s \n", $txml->getRootNode(1)->countChildren);
my @children = $txml->getRootNode(1)->children;

warn Dumper(\@children);

print "Original hash: \n";
warn Dumper($hash);
print "Reimported hash: \n";
warn Dumper($txml->toHash);
undef($txml);
#my $txml2 = XML::TinyXML->new();
#$txml2->loadBuffer($txml->dump);

#warn Dumper($txml2->toHash);
#printf("%s \n", $txml2->dump);

my $txml = XML::TinyXML->new();
$txml->loadFile("./t/t.xml");
printf("%s \n", $txml->dump);
my $testnode = $txml->getNode("/xml/foo");
print Dumper($testnode);
print $testnode->name ."\n";
foreach my $k ($testnode->children) {
    print $k->type . "\n";
}


