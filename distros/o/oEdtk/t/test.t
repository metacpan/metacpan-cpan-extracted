#!./perl
use lib qw(t );
use Test::More;
plan tests => 24;

use oEdtk::Main; 
ok 1, "Loaded";

use oEdtk::Run; 
ok 2, "Loaded";

use oEdtk::Config; 
ok 3, "Loaded";

use oEdtk::DBAdmin; 
ok 4, "Loaded";

use oEdtk::Outmngr; 
ok 5, "Loaded";

use oEdtk::Dict; 
ok 6, "Loaded";

use oEdtk::Tracking; 
ok 7, "Loaded";

use oEdtk::Util; 
ok 8, "Loaded";

use oEdtk::EDMS; 
ok 9, "Loaded";

use oEdtk::Spool; 
ok 10, "Loaded";

use oEdtk::Field; 
ok 11, "Loaded";

use oEdtk::FPField; 
ok 12, "Loaded";

use oEdtk::Record; 
ok 13, "Loaded";

use oEdtk::RecordParser; 
ok 14, "Loaded";

use oEdtk::SignedField; 
ok 15, "Loaded";

use oEdtk::Doc; 
ok 16, "Loaded";

use oEdtk::TexDoc; 
ok 17, "Loaded";

use oEdtk::C7Doc; 
ok 18, "Loaded";

use oEdtk::AddrField; 
ok 19, "Loaded";

use oEdtk::DateField; 
ok 20, "Loaded";

use oEdtk::Messenger; 
ok 21, "Loaded";

use oEdtk::XPath; 
ok 22, "Loaded";

use oEdtk::libXls;
ok 23, "Loaded";

use XML::LibXML;
ok 24, "Loaded"; 

#chdir 't';
#require "test_fixe_oEdtk.pl" ;
#ok 25, "Loaded";
#run();
#ok 26, "Run test application";

END
{
    #for ($file1, $file2, $stderr) { 1 while unlink $_ } ;
}
