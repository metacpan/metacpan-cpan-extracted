package AstDumpParser;
use Ast;

$nodeName = "aaaa"; # Used to name those nodes that have not been explicitly
		    # named in the input file

sub Parse{
    my ($fileName) = shift;
    my ($ROOT);
    open (P, $fileName) || die "Could not open $fileName : $@";
    
    while (GetLine()) {
	if ($line =~ /^ *\(\s*([A-z]+)\s*([A-z]*)/) {
	    # New node . e.g "( ROOT :101". The ":101" is an optional number
	    # given to tag this node, and can be  referred to later as
	    # "somepropertyname  node:1"; "node-" is a keyword followed by
	    #  a node id

	    if (! $1) {
		$1 = "temp-" . $nodeName++;
	    }
	    $currNode = Ast::New($1);
	    if (! $ROOT) {
		$ROOT = $currNode;
	    }
	    if ($2) {
		$oidArray{$2} = $currNode;
	    }
	    push(@nodes, $currNode);
	    if ($listName) {
		$listNode->AddPropList ($listName, $currNode);
	    }
	} elsif ($line =~ /^\s*\)/) {
	    # End of current node definition
	    $currNode = pop (@nodes);
	} elsif ($line =~ /^\s*\[\s*([A-z]+)/) {
	    # A vector property of current node
	    if (! $1 ) {
		FatalError 
		    ("Error :Array name expected at line $. ... exiting\n; ");
	    }
	    $listName = $1; $listNode = $currNode;
	} elsif ($line =~ /^\s*\]/) {
	    $listName = ""; $listNode = "";
	} else {
	    # a name - value pair
	    ($name, $value) = ($line =~ /^\s*([A-z]+)\s*(.+)/);
	    if (!($name && $value)) {
		FatalError ("Invalid Attribute at line $. \n");
	    }
	    if ($value =~ /^:\S+/) {
		$v = $nodes{$value};
		if (! $v) {
		    print "Invalid reference to object $value at line $.\n";
		} else {
		    $value = $v;
		}
	    }
	    $currNode->AddProp($name, $value);
	}
    }
    return ($ROOT);
}

sub FatalError {
    print @_, "\n";
    exit (1);
}

sub GetLine {
    while ($line = <P>) {
	$line =~ s#//.*$##;
	return $line if ($line !~ /^\s*$/);
    }
}
1;



