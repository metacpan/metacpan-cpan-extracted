use Test::More 'no_plan';
use Data::Compare qw( Compare );

use Cwd;
$dir = cwd;
print "Directory: $dir\n";
print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::DB::File');
use perfSONAR_PS::DB::File;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::new tests

$fileBlank = perfSONAR_PS::DB::File->new( { file => './t/testfiles/blank.xml' } );
$fileNotExist = perfSONAR_PS::DB::File->new( { file => './t/testfiles/doesnotexist.xml' } );
$fileXML = perfSONAR_PS::DB::File->new( { file => './t/testfiles/simpleXML.xml' } );
$fileGarbage = perfSONAR_PS::DB::File->new( { file => './t/testfiles/garbage0.xml' } );
$fileXMLNoTag = perfSONAR_PS::DB::File->new;
ok(defined $fileBlank, "DB::File::new - Blank file");
ok(defined $fileNotExist, "DB::File::new - Non-existant file");
ok(defined $fileXML, "DB::File::new - XML file");
ok(defined $fileGarbage, "DB::File::new - Garbage file");
ok(defined $fileXMLNoTag, "DB::File::new - Small XML no tag file");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::setFile

$fileXMLNoTag->setFile( { file => './t/testfiles/simpleXMLNotag.xml' } );
is ($fileXMLNoTag->{FILE}, './t/testfiles/simpleXMLNotag.xml');

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::openDB

#Not sure how we're going to handle these
#$fileBlank->openDB();
#$fileNotExist->openDB;
#$fileGarbage->openDB();
#$fileXMLNoTag->openDB();
$fileXML->openDB();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::query

@results = $fileXML->query( { query => "/alpha/charley | /alpha/beta/charley/done/england | /alpha/beta[2]" } );
@expected = ("<charley>\n\t\t<dog europe=\"good\"/>\n\t</charley>", "<beta/>", "<england super=\"man\">\n\t\t\t\t\tFreaky\n\t\t\t\t</england>");
ok(Compare(\@results, \@expected), "DB::File::query - XPath '/alpha/charley | /alpha/beta/charley/done/england | /alpha/beta[2]'");

@results = $fileXML->query( { query => "//madeup" } );
@expected = ();
ok(Compare(\@results, \@expected), "DB::File::query - XPath '//madeup'");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::count

$cnt = $fileXML->count( { query => "/alpha/beta" } );
is($cnt, 3, "DB::File::count - XPath '/alpha/beta'");
$cnt = $fileXML->count( { query => "/alpha/beta/charley" } );
is($cnt, 2, "DB::File::count - XPath '/alpha/beta/charley'");
$cnt = $fileXML->count( { query => "//*" } );
is($cnt, 10, "DB::File::count - XPath '//*'");
$cnt = $fileXML->count( { query => "//charley" } );
is($cnt, 3, "DB::File::count - XPath '//charley'");
$cnt = $fileXML->count( { query => "//@*" } );
is($cnt, 3, "DB::File::count - XPath '//@*'");
$cnt = $fileXML->count( { query => "//madeup" } );
is($cnt, 0, "DB::File::count - XPath '//madeup'");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::getDOM

$originalDOM = $fileXML->getDOM;
is($originalDOM->version, "1.0", "DB::File::getDOM - version number is correct");


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::File::setDOM

$fileXML->setDOM( { dom => XML::LibXML::Document->new("1.234", "UTF-8") } );
is($fileXML->getDOM()->version, "1.234", "DB::File::setDOM - altered version number is correct");
$fileXML->setDOM( { dom => $originalDOM } );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#DB::File::closeDB

$fileXML->closeDB;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

