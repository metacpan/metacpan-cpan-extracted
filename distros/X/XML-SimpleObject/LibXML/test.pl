# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::SimpleObject::LibXML;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $XML = <<END;
  <files>
    <file type="symlink">
      <name>/etc/dosemu.conf</name>
      <dest>dosemu.conf-drdos703.eval</dest>
      <bytes>0</bytes>
    </file>
    <file>
      <name>/etc/passwd</name>
      <bytes>948</bytes>
    </file>
  </files>
END

my $parser = new XML::LibXML;
my $xmlobj = new XML::SimpleObject::LibXML ($parser->parse_string($XML));

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

