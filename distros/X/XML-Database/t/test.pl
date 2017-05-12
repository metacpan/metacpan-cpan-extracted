#use lib "C:/Documents and Settings/isterin/Desktop";
use XML::Database;
use XML::Database::Tables;
use XML::Database::Records;

my $xmldb = XML::Database->new();

$xmldb->create(Name => "membership", Directory => ".");

my $xmltables = XML::Database::Tables->new(Database => $xmldb);

$xmltables->create(TableName => "members", DTDFile => 'test.dtd');
$xmltables->create(TableName => "products");

my @tables = $xmltables->tables();

print "Tables: @tables\n\n";

$xmlrecords = XML::Database::Records->new(Tables => $xmltables);

$xmlrecords->insertRecord(RecordName => "1", RecordData => <<XML);
<?xml version="1.0"?>
<record>
<name>Ilya Sterin</name>
<name>Crystal Sterin</name>
<name>Elijah Sterin</name>
</record>
XML

$xmlrecords->insertRecord(RecordName => "2", RecordData => <<XML);
<?xml version="1.0"?>
<record>
<name>Ilya</name>
<name>Crystal</name>
<name>Elijah</name>
</record>
XML

my @records = $xmlrecords->records();

print "@records\n\n";

while (my @data = $xmlrecords->fetchrowArray(Node => 'record/name', Value => 'name', Match => 'Sterin'))
{
	print "@data\n";
	#exit unless @data;
}
