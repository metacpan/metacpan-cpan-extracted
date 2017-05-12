use XML::DOM;
use strict;

my $parser = new XML::DOM::Parser;

my $filename = $ARGV[0] || (-f "macros.xpl" ? "macros.xpl" : "htpl.subs");

die "$filename.old exists" if (-f "$filename.old");

my $doc = $parser->parsefile($filename);

my $root = $doc->getDocumentElement;

my $n;

&recur($root, 1);

use File::Copy;
copy($filename, "$filename.old");
unlink $filename;

open(O, ">macros.xpl");
print O <<EOM;
<?xml version="1.0" ?>
<!DOCTYPE XPL>
EOM
print O $root->toString;
close(O);
print "macros.xpl created. $n macros converted.\n";

sub recur {
    my $node = shift;
    my $name = $node->getTagName;
    &manip($node) unless ($name =~ /^__/ || @_);
    my @children = $node->getChildNodes;
    foreach (@children) {
        &recur($_) if ($_->getNodeType == ELEMENT_NODE);
    }
}

sub manip {
    $n++;
    my $node = shift;
    my $name = $node->getTagName;
    $node->setTagName("__MACRO");
    $node->setAttribute('NAME', $name);
}
