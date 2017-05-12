# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 8;

use XML::SimpleObject::LibXML;

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
ok($parser);
my $xmlobj = new XML::SimpleObject::LibXML ($parser->parse_string($XML));
ok($xmlobj);

is(($xmlobj->child("files")->children("file"))[0]->child("name")->value,
     "/etc/dosemu.conf");
is(($xmlobj->child("files")->children("file"))[0]->attribute("type"),
     "symlink");
is(($xmlobj->child("files")->children("file"))[1]->child("name")->value,
     "/etc/passwd");

($xmlobj->child("files")->children("file"))[0]->child("name")->add_attribute
     ("lang", "en");
is(($xmlobj->child("files")->children("file"))[0]->child("name")->attribute("lang"),
     "en");

my $child = ($xmlobj->child("files")->children("file"))[0]->child("name")->add_child
     ("tmp", "try");
is($child->name,"tmp");
is($child->value,"try");

