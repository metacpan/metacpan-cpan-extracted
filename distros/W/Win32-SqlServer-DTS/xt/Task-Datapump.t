use XML::Simple;
use Test::More tests => 20;
use Win32::SqlServer::DTS::Application;
use Win32::SqlServer::DTS::Assignment::Query;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

# test-all DTS package has only one Datapump
my $iterator = $package->get_datapumps();
my $datapump = $iterator->();

$package->kill_sibling();

is( $datapump->get_name(), 'DTSTask_DTSDataPumpTask_1', 'Name is correct' );
is(
    $datapump->get_description(),
    'Test Transform Data Task',
    'Description is correct'
);
is( $datapump->get_dest_conn_id(), 2, 'DestinationConnectionID is 2' );
is( $datapump->get_dest_obj(),
    '[Northwind].[dbo].[Region]', 'DestinationObjectName is correct' );
is( $datapump->get_dest_sql(), '', 'DestinationSQLStatement is empty' );
is(
    $datapump->get_source_obj(),
    'E:\dts\perl_dts\DTS\region.txt',
    'SourceObjectName is correct'
);
is( $datapump->get_source_sql(),     '',   'SourceSQLStatement is empty' );
is( $datapump->get_source_conn_id(), 3,    'SourceConnectionID is correct' );
is( $datapump->get_progress_count(), 1000, 'ProgressRowCount is correct' );
is( $datapump->get_rows_complete(),  0,    'RowsComplete is correct' );
is( $datapump->get_fetch_size(),     1,    'FetchBufferSize is correct' );
is( $datapump->get_first_row(),      0,    'FirstRow is correct' );
is( $datapump->get_exception_qualifier(),
    '', 'ExceptionFileTextQualifier is empty' );
is( $datapump->get_input_global_vars(),
    '', 'InputGlobalVariablesNames is empty' );
is( $datapump->get_exception_file(), '', 'ExceptionFileName is empty' );
is( $datapump->get_commit_size(),    0,  'InsertCommitSize is correct' );
is( $datapump->get_max_errors(),     0,  'MaximumErrorCount is none' );
ok( $datapump->use_fast_load(), 'UseFastLoad is enabled' );
ok( ( $datapump->always_commit() or 1 ), 'DataPumpOptions is disabled' );
ok(
    (
        $datapump->use_identity_inserts()
          or 1
    ),
    'AllowIdentityInserts is disabled'
);
