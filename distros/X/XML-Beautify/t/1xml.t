# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Beautify;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $ref_XML = XML::Beautify->new(
									'DEBUG'=>0,
								);

$cleanXML = <<CLEAN_XML;
<?xml version="1.0"?>
<SashRegistry version=".99">
  <key name="^Top">
    <key name="title">
      <value name="(Default)" type="string"><![CDATA[53617368465450]]></value>
    </key>
    <key name="abstract">
      <value name="(Default)" type="string"><![CDATA[412073696d706c65206d756c746974687265616465642046545020636c69656e74]]></value>
    </key>
    <key name="author">
      <value name="(Default)" type="string"><![CDATA[536173685842205465616d]]></value>
    </key>
  </key>
</SashRegistry>
CLEAN_XML

my $dirtyXML = <<DIRTY_XML;
<?xml version="1.0"?><SashRegistry version=".99"><key name="^Top"><key name="title"><value name="(Default)" type="string"><![CDATA[53617368465450]]></value></key><key name="abstract"><value name="(Default)" type="string"><![CDATA[412073696d706c65206d756c746974687265616465642046545020636c69656e74]]></value></key><key name="author"><value name="(Default)" type="string"><![CDATA[536173685842205465616d]]></value></key></key></SashRegistry>
DIRTY_XML

if(ref($ref_XML) eq 'XML::Beautify'){
	print("ok 2\n");
}
else{
	print("not ok 2\n");
}

$ref_XML->indent_str('  ');
###HERE Make this a test.

my $newXML = $ref_XML->beautify(\$dirtyXML);

###HERE Bad test
if($newXML ne $cleanXML){
	print("ok 3\n");
}
else{
	print("not ok 3\n");
}
