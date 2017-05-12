use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
print "NOTE: XML::SimpleObject requires XML::Parser. If you have XML::LibXML, you 
can install XML::SimpleObject::LibXML instead.\n
Checking for XML::Parser ... \n";
require XML::Parser;
print "OK\n";

WriteMakefile(
    'NAME'	=> 'XML::SimpleObject',
    'VERSION_FROM' => 'SimpleObject.pm', # finds $VERSION
);
