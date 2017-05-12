# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-TreePP-XMLPath.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('XML::TreePP'); 
        use_ok('XML::TreePP::XMLPath');
        use_ok('XML::TreePP::Editor');
        #use_ok('Data::Dump', 'pp');
        use_ok('Data::Dumper');
      };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$Data::Dumper::Indent = 0;
$Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;

my $tpp = XML::TreePP->new();
my $tppx = XML::TreePP::XMLPath->new();
my $tppe = XML::TreePP::Editor->new();

ok ( defined($tppe) && ref $tppe eq 'XML::TreePP::Editor', 'new()' );

## Example Test XML Document
my $xmldoc =<<XML_EOF;
<test>
  <node id="one">
    <data>test data one</data>
  </node>
  <node id="two">
    <data>test data two</data>
  </node>
  <node id="three">
    <data>
        <test>1</test>
        <![CDATA[<html><body>test data three</body></html>]]>
    </data>
  </node>
</test>
XML_EOF

my $tree = $tpp->parse($xmldoc);
my ($path, $result, $newnode, $newtree);

## Test inserting new node into XML Document
$newnode    = { -id => "four", data => "test data four - insert" };
$newtree    = eval( Dumper($tree) );
$path       = "/test/node";
$result     = $tppe->modify($newtree, $path, insert => $newnode);
ok ( $result == 1 && $newtree->{'test'}->{'node'}->[0]->{'data'} eq "test data four - insert", "modify( insert )" ) || diag explain $newtree;

# Test replacing a node
$newnode    = { -id => "four", data => "test data four - replace" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[3]';
$result     = $tppe->modify($newtree, $path, replace => $newnode);
ok ( $result == 1 && $newtree->{'test'}->{'node'}->[2]->{'data'} eq "test data four - replace", "modify( replace ) single" ) || diag explain $newtree;

# Test replacing all child nodes
$newnode    = { -id => "four", data => "test data four - replace" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node';
$result     = $tppe->modify($newtree, $path, replace => $newnode);
ok ( $result == 3 && $newtree->{'test'}->{'node'}->[2]->{'data'} eq "test data four - replace", "modify( replace ) all" ) || diag explain $newtree;

# Test deleting a single node
$newnode    = { -id => "four", data => "test data four - delete" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[1]';
$result     = $tppe->modify($newtree, $path, delete => undef);
ok ( $result == 1 && $newtree->{'test'}->{'node'}->[0]->{'data'} eq "test data two", "modify( delete ) single" ) || diag explain $newtree;

# Test deleting all child nodes
$newtree    = eval( Dumper($tree) );
$path       = '/test/node';
$result     = $tppe->modify($newtree, $path, delete => undef);
ok ( $result == 3, "modify( delete ) all" ) || diag explain $newtree;

# Test mergeadd on a node
$newnode    = { -id => "four", dataadd => "test data four - mergeadd" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[@id="three"]';
$result     = $tppe->modify($newtree, $path, mergeadd => $newnode);
ok ( $result == 1 && $newtree->{'test'}->{'node'}->[2]->{'dataadd'} eq "test data four - mergeadd", "modify( mergeadd )" ) || diag explain $newtree;

# Test mergeappend on a node
$newnode    = { -id => "four", data => " - mergeappend" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[@id="two"]';
$result     = $tppe->modify($newtree, $path, mergeappend => $newnode);
ok ( $result == 2 
     && $newtree->{'test'}->{'node'}->[1]->{'data'} eq "test data two - mergeappend"
     && $newtree->{'test'}->{'node'}->[1]->{'-id'} eq "twofour", "modify( mergeappend )" ) || diag explain $newtree;

TODO: {
local $TODO = "Cannot mergeappend on complex nodes yet.";
# Test mergeappend on a node's special text element
$newnode    = { data => " - mergeappend" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[@id="three"]';
$result     = $tppe->modify($newtree, $path, mergeappend => $newnode);
ok ( $result == 1 && $newtree->{'test'}->{'node'}->[2]->{'data'}->{'#text'} eq "<html><body>test data three</body></html> - mergeappend", "modify( mergeappend ) special text element" ); # || diag explain $newtree;
}

# Test mergereplace on a node
$newnode    = { -id2 => "four", data => "test data four - mergereplace" };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[@id="one"]';
$result     = $tppe->modify($newtree, $path, mergereplace => $newnode);
ok ( $result == 2 
     && $newtree->{'test'}->{'node'}->[0]->{'data'} eq "test data four - mergereplace"
     && $newtree->{'test'}->{'node'}->[0]->{'-id2'} eq "four", "modify( mergereplace )" ) || diag explain $newtree;

# Test mergedelete on a node
$newnode    = { data => undef };
$newtree    = eval( Dumper($tree) );
$path       = '/test/node[@id="three"]';
$result     = $tppe->modify($newtree, $path, mergedelete => $newnode);
ok ( $result == 1
    && ! exists $newtree->{'test'}->{'node'}->[2]->{'data'}
    && $newtree->{'test'}->{'node'}->[2]->{'-id'} eq "three", "modify( mergedelete )" ) || diag explain $newtree;


