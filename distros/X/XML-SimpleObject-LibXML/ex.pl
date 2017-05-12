use XML::SimpleObject::LibXML;
use strict;

my $XML = <<EOF;

  <files>
    <file type="symlink">
      <name>/etc/dosemu.conf</name>
      <dest>dosemu.conf-drdos703.eval</dest>
      <bytes><hi>cool</hi>20</bytes>
    </file>
    <file>
      <name>/etc/passwd</name>
      <bytes>948</bytes>
    </file>
  </files>

EOF

my $xmlobj = new XML::SimpleObject::LibXML(XML => $XML);

# or:
# my $parser = new XML::LibXML;
# my $xmlobj = new XML::SimpleObject::LibXML ($parser->parse_string($XML));

print "\n";

{
  print "Files: \n";
  foreach my $element ($xmlobj->child("files")->children("file")) 
  {
    print "  filename: " . $element->child("name")->value . "\n";
    if ($element->attribute("type"))
    {
      print "    type: " . $element->attribute("type") . "\n";
    }
    print "    bytes: " . $element->child("bytes")->value . "\n";
  }
}

print "\n";

{
  my $filesobj = $xmlobj->child("files")->child("file");
  foreach my $child ($filesobj->children) {
    print "child: ", $child->name, ": ", $child->value, "\n";
  }
}

print "\n";

{
  my $filesobj = $xmlobj->child("files");
  foreach my $childname ($filesobj->children_names) {
      print "$childname has children: ";
      print join (", ", $filesobj->child($childname)->children_names), "\n"; 
  }
}

print "\n";

{
  print "First filename: " . $xmlobj->xpath_search("/files/file[1]/name")->value . "\n";
}

{
  $xmlobj->xpath_search("/files/file[1]/name")->value("testfilename.txt");
   print "Changed first filename: " . $xmlobj->xpath_search("/files/file[1]/name")->value . "\n";
}

{
  my $filenode = $xmlobj->xpath_search("/files/file[1]");
  $filenode->attribute("type","newtype");
  print "Changed attribute value: " . $filenode->attribute("type") . "\n";
}

{
  $xmlobj->xpath_search("/files/file[1]")->add_child("owner" => "Dan", attr => { phone => "123-2345" } );
  print "Added child: " . $xmlobj->xpath_search("/files/file[1]/owner")->value . "\n";
}

{
  $xmlobj->xpath_search("/files/file[2]")->add_attribute("new_attr" => "new_value");
  print "Added attribute: " . $xmlobj->xpath_search("/files/file[2]")->attribute("new_attr") . "\n";
}

{
  $xmlobj->xpath_search("/files")->name("Files");
  print "Changed element name: " . $xmlobj->child()->name . "\n";
}

{
  $xmlobj->xpath_search("/Files/file[1]/dest")->delete;
  $xmlobj->xpath_search("/Files/file[1]")->value("");
  print "Deleted element.\n";
}
#  $xmlobj->replace_names_values(xpath => "/Files/file/name", value => "allyourfilesowned", name => "myname");
#  $xmlobj->delete_nodes(xpath => "/Files/file");
{
  print "Output: " . $xmlobj->output_xml;
}
