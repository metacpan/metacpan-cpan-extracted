#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese :hireswallclock);
use File::Temp qw(tempfile tempdir);

use XML::PugiXML;
use XML::LibXML;

print "XML::PugiXML vs XML::LibXML Benchmark\n";
print "=" x 60, "\n\n";

# Generate test XML of various sizes
sub generate_xml {
    my ($items) = @_;
    my $xml = qq{<?xml version="1.0"?>\n<root>\n};
    for my $i (1 .. $items) {
        $xml .= qq{  <item id="$i" category="cat@{[$i % 10]}" active="@{[$i % 2 ? 'true' : 'false']}">\n};
        $xml .= qq{    <name>Item number $i</name>\n};
        $xml .= qq{    <description>This is the description for item $i with some text content.</description>\n};
        $xml .= qq{    <price>@{[sprintf "%.2f", rand(1000)]}</price>\n};
        $xml .= qq{    <tags>\n};
        for my $t (1 .. 3) {
            $xml .= qq{      <tag>tag@{[$i * $t % 20]}</tag>\n};
        }
        $xml .= qq{    </tags>\n};
        $xml .= qq{  </item>\n};
    }
    $xml .= qq{</root>\n};
    return $xml;
}

# Test sizes
my @sizes = (100, 1000, 5000);

for my $size (@sizes) {
    print "\n", "=" x 60, "\n";
    print "Test with $size items\n";
    print "=" x 60, "\n";

    my $xml = generate_xml($size);
    my $xml_len = length($xml);
    print "XML size: $xml_len bytes\n\n";

    # Write to temp file for file parsing tests
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.xml', UNLINK => 1);
    print $fh $xml;
    close $fh;

    # Temp dir for output tests
    my $tmpdir = tempdir(CLEANUP => 1);

    #--------------------------------------------------
    # 1. Parse string
    #--------------------------------------------------
    print "1. Parse string ($size items):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string($xml);
        },
        'LibXML' => sub {
            my $parser = XML::LibXML->new;
            my $doc = $parser->parse_string($xml);
        },
    });
    print "\n";

    #--------------------------------------------------
    # 2. Parse file
    #--------------------------------------------------
    print "2. Parse file ($size items):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_file($tmpfile);
        },
        'LibXML' => sub {
            my $parser = XML::LibXML->new;
            my $doc = $parser->parse_file($tmpfile);
        },
    });
    print "\n";

    # Pre-parse documents for subsequent tests
    my $pugi_doc = XML::PugiXML->new;
    $pugi_doc->load_string($xml);

    my $libxml_parser = XML::LibXML->new;
    my $libxml_doc = $libxml_parser->parse_string($xml);

    #--------------------------------------------------
    # 3. XPath: select single node
    #--------------------------------------------------
    print "3. XPath select single node:\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $node = $pugi_doc->select_node('//item[@id="500"]');
        },
        'LibXML' => sub {
            my ($node) = $libxml_doc->findnodes('//item[@id="500"]');
        },
    });
    print "\n";

    #--------------------------------------------------
    # 4. XPath: select multiple nodes
    #--------------------------------------------------
    print "4. XPath select multiple nodes (all items):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my @nodes = $pugi_doc->select_nodes('//item');
        },
        'LibXML' => sub {
            my @nodes = $libxml_doc->findnodes('//item');
        },
    });
    print "\n";

    #--------------------------------------------------
    # 5. XPath with predicate
    #--------------------------------------------------
    print "5. XPath with predicate (category=cat5):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my @nodes = $pugi_doc->select_nodes('//item[@category="cat5"]');
        },
        'LibXML' => sub {
            my @nodes = $libxml_doc->findnodes('//item[@category="cat5"]');
        },
    });
    print "\n";

    #--------------------------------------------------
    # 6. Tree traversal - iterate all children
    #--------------------------------------------------
    print "6. Tree traversal (iterate all item children):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $root = $pugi_doc->root;
            my $count = 0;
            for my $item ($root->children('item')) {
                $count++ if $item->child('name');
            }
        },
        'LibXML' => sub {
            my $root = $libxml_doc->documentElement;
            my $count = 0;
            for my $item ($root->childNodes) {
                next unless $item->nodeType == 1 && $item->nodeName eq 'item';
                $count++ if $item->getElementsByTagName('name')->[0];
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 7. Attribute access
    #--------------------------------------------------
    print "7. Attribute access (get id from all items):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $root = $pugi_doc->root;
            my @ids;
            for my $item ($root->children('item')) {
                push @ids, $item->attr('id')->value;
            }
        },
        'LibXML' => sub {
            my $root = $libxml_doc->documentElement;
            my @ids;
            for my $item ($root->childNodes) {
                next unless $item->nodeType == 1 && $item->nodeName eq 'item';
                push @ids, $item->getAttribute('id');
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 8. Text content extraction
    #--------------------------------------------------
    print "8. Text content extraction (get all names):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my @names;
            for my $node ($pugi_doc->select_nodes('//name')) {
                push @names, $node->text;
            }
        },
        'LibXML' => sub {
            my @names;
            for my $node ($libxml_doc->findnodes('//name')) {
                push @names, $node->textContent;
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 9. Document creation (append children)
    #--------------------------------------------------
    print "9. Document creation (append 100 children with attrs):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string('<root/>');
            my $root = $doc->root;
            for my $i (1..100) {
                my $item = $root->append_child('item');
                $item->append_attr('id')->set_value($i);
                $item->append_attr('name')->set_value("item_$i");
                $item->set_text("Item $i");
            }
        },
        'LibXML' => sub {
            my $doc = XML::LibXML::Document->new('1.0');
            my $root = $doc->createElement('root');
            $doc->setDocumentElement($root);
            for my $i (1..100) {
                my $item = $doc->createElement('item');
                $item->setAttribute('id', $i);
                $item->setAttribute('name', "item_$i");
                $item->appendText("Item $i");
                $root->appendChild($item);
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 10. Node removal (remove half the children)
    #--------------------------------------------------
    print "10. Node removal (remove every other child):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string($xml);
            my $root = $doc->root;
            my @items = $root->children('item');
            for (my $i = 0; $i < @items; $i += 2) {
                $root->remove_child($items[$i]);
            }
        },
        'LibXML' => sub {
            my $parser = XML::LibXML->new;
            my $doc = $parser->parse_string($xml);
            my $root = $doc->documentElement;
            my @items = grep { $_->nodeType == 1 && $_->nodeName eq 'item' } $root->childNodes;
            for (my $i = 0; $i < @items; $i += 2) {
                $root->removeChild($items[$i]);
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 11. Attribute removal (remove one attr from all nodes)
    #--------------------------------------------------
    print "11. Attribute removal (remove 'active' from all items):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string($xml);
            my $root = $doc->root;
            for my $item ($root->children('item')) {
                $item->remove_attr('active');
            }
        },
        'LibXML' => sub {
            my $parser = XML::LibXML->new;
            my $doc = $parser->parse_string($xml);
            my $root = $doc->documentElement;
            for my $item ($root->childNodes) {
                next unless $item->nodeType == 1 && $item->nodeName eq 'item';
                $item->removeAttribute('active');
            }
        },
    });
    print "\n";

    #--------------------------------------------------
    # 12. Mixed manipulation (add, modify, remove)
    #--------------------------------------------------
    print "12. Mixed manipulation (modify tree structure):\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string('<root><a/><b/><c/><d/><e/></root>');
            my $root = $doc->root;
            # Add new nodes
            for my $i (1..10) {
                my $n = $root->append_child('new');
                $n->append_attr('id')->set_value($i);
            }
            # Remove some
            $root->remove_child($root->child('b'));
            $root->remove_child($root->child('d'));
            # Modify
            $root->child('a')->set_name('alpha');
            $root->child('c')->set_text('modified');
        },
        'LibXML' => sub {
            my $doc = XML::LibXML->new->parse_string('<root><a/><b/><c/><d/><e/></root>');
            my $root = $doc->documentElement;
            # Add new nodes
            for my $i (1..10) {
                my $n = $doc->createElement('new');
                $n->setAttribute('id', $i);
                $root->appendChild($n);
            }
            # Remove some
            my ($b) = $root->findnodes('b');
            my ($d) = $root->findnodes('d');
            $root->removeChild($b);
            $root->removeChild($d);
            # Modify
            my ($a) = $root->findnodes('a');
            $a->setNodeName('alpha');
            my ($c) = $root->findnodes('c');
            $c->appendText('modified');
        },
    });
    print "\n";

    #--------------------------------------------------
    # 13. Save to file
    #--------------------------------------------------
    print "13. Save to file:\n";
    my $pugi_out = "$tmpdir/pugi_out.xml";
    my $libxml_out = "$tmpdir/libxml_out.xml";
    cmpthese(-2, {
        'PugiXML' => sub {
            $pugi_doc->save_file($pugi_out);
        },
        'LibXML' => sub {
            $libxml_doc->toFile($libxml_out);
        },
    });
    print "\n";

    #--------------------------------------------------
    # 14. Serialize to string
    #--------------------------------------------------
    print "14. Serialize to string:\n";
    cmpthese(-2, {
        'PugiXML' => sub {
            my $str = $pugi_doc->to_string;
        },
        'LibXML' => sub {
            my $str = $libxml_doc->toString;
        },
    });
    print "\n";

    #--------------------------------------------------
    # 15. Full round-trip (parse + modify + serialize)
    #--------------------------------------------------
    print "15. Full round-trip (parse, modify 10 nodes, save):\n";
    my $small_xml = generate_xml(100);
    cmpthese(-2, {
        'PugiXML' => sub {
            my $doc = XML::PugiXML->new;
            $doc->load_string($small_xml);
            my $root = $doc->root;
            my @items = $root->children('item');
            for my $i (0..9) {
                $items[$i]->set_text("Modified $i");
                $items[$i]->append_attr('modified')->set_value('true');
            }
            $doc->save_file("$tmpdir/rt_pugi.xml");
        },
        'LibXML' => sub {
            my $doc = XML::LibXML->new->parse_string($small_xml);
            my $root = $doc->documentElement;
            my @items = grep { $_->nodeType == 1 && $_->nodeName eq 'item' } $root->childNodes;
            for my $i (0..9) {
                $items[$i]->appendText("Modified $i");
                $items[$i]->setAttribute('modified', 'true');
            }
            $doc->toFile("$tmpdir/rt_libxml.xml");
        },
    });
    print "\n";
}

print "\n", "=" x 60, "\n";
print "Benchmark complete.\n";
