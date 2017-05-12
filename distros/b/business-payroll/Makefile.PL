#$Id: Makefile.PL,v 1.4 2004/10/08 20:02:18 pcxuser Exp $
#This package is released under the GNU General Public License.
#You should have recieved a copy of the GPL with it.
# Copyright (c) 2002 Xperience, Inc. http://www.pcxperience.org  
# All rights reserved.
require 5.004;
use strict;

my $NAME    = 'Business::Payroll';
my $DISTNAME = "business-payroll";
my $fileTempVersion = "0.12";
my $xmlSaxVersion = "0.10";
my $xmlLibXMLVersion = "1.51";

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;

print "Checking for File::Temp.........";
eval {
    require File::Temp;
    File::Temp->VERSION($fileTempVersion);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The File::Temp module version $fileTempVersion must be installed.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for XML::SAX.........";
eval {
    require XML::SAX;
    XML::SAX->VERSION($xmlSaxVersion);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The XML::SAX module version $xmlSaxVersion must be installed.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for XML::LibXML.........";
eval {
    require XML::LibXML;
    XML::LibXML->VERSION($xmlLibXMLVersion);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The XML::LibXML module version $xmlLibXMLVersion must be installed.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

if ($missing_modules)
{
  print <<EOT;
The missing modules can be obtained from CPAN.  Visit
<URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT
  exit(1);
}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'      => $NAME,
    'VERSION_FROM'   => "Payroll.pm", #$VERSION,
    'DISTNAME'  => $DISTNAME,
    'PREREQ_PM' => { 'File::Temp' => $fileTempVersion, 'XML::SAX' => $xmlSaxVersion, 'XML::LibXML' => $xmlLibXMLVersion },
    'AUTHOR'    => 'James A. Pattie <james@pcxperience.com>',
    'ABSTRACT'  => 'Business Payroll Modules.',
);
