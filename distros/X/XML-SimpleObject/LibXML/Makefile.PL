use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "NOTE: XML::SimpleObject::LibXML requires XML::LibXML. If you have XML::Parser
you can install XML::SimpleObject instead.\n
Checking for XML::LibXML ... \n";
require XML::LibXML;
print "OK\n";
WriteMakefile(
    'NAME'	=> 'XML::SimpleObject::LibXML',
    'VERSION_FROM' => 'LibXML.pm', # finds $VERSION
);
