use XML::Simple;
use Test::More tests => 23;
use Win32::SqlServer::DTS::Application;
use Win32::OLE qw(in);

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

is( ref( $package->get_steps() ),
    'CODE', 'get_steps method returns a code reference' );

is_deeply( $package->execute(), fetch_steps_results(),
'execute method returns an array reference with Win32::SqlServer::DTS::Package::Step::Results objects'
);

ok( not( $package->log_to_server() ), 'log to server is disable' );
ok( $package->auto_commit(),          'auto commit is active' );
ok(
    $package->use_explicit_global_vars(),
    'explicit global variables are active'
);
ok( not( $package->fail_on_error() ), 'fail on error is inactive' );

ok(
    not( $package->add_lineage_vars() ),
    'Add Lineage Variables property is false'
);

ok( $package->is_lineage_none(), 'Lineage None property is active' );

ok( not( $package->is_repository() ),
    'package will not write to Meta Data Services' );
ok(
    not( $package->is_repository_required() ),
    'Meta Data services is not required'
);

ok( $package->to_string(), 'to_string returns a true value' );

is( ref( $package->get_connections() ),
    'CODE', 'get_connections returns a code reference' );

ok( $package->count_connections() == 2, 'package has two connections' );

is( ref( $package->get_tasks() ), 'CODE', 'get_tasks returns a iterator' );

is( $package->count_tasks(), 5, 'package has 5 tasks' );

is( ref( $package->get_datapumps() ),
    'CODE', 'get_datapump returns a code reference' );

ok( $package->count_datapumps() == 1, 'package has one datapump' );

is( ref( $package->get_dynamic_props() ),
    'CODE', 'get_dynamic_props returns a code reference' );

ok( $package->count_dynamic_props() == 1, 'package has one datapump' );

is( ref( $package->get_execute_pkgs() ),
    'CODE', 'get_execute_pkgs returns a code reference' );

ok(
    $package->count_execute_pkgs() == 1,
    'package has one Execute Package task'
);

is( ref( $package->get_send_emails() ),
    'CODE', 'get_send_emails method returns a code reference' );

ok( $package->count_send_emails() == 1, 'package has one Send Mail Task' );

sub fetch_steps_results {

    my $steps = $package->get_sibling()->Steps;
    my $collection;

    foreach my $step ( in($steps) ) {

        my $new_step = Win32::SqlServer::DTS::Package::Step->new($step);

        push( @{$collection}, $new_step->get_exec_error_info() );

    }

    return $collection;

}
