use warnings;
use strict;
use Win32::SqlServer::DTS::Application;
use Test::More;
use XML::Simple;
use Benchmark qw(cmpthese);
use constant XML_FILE => 'modify.xml';

my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml);
my $pkg_name = $config->{package};

my $unique_app       = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $total_executions = 20;

plan tests => ( 6 * $total_executions ) * 2;

cmpthese( $total_executions,
    { highlander_app => \&unique_app, orcs_apps => \&several_apps } );

sub unique_app {

    my $package = $unique_app->get_db_package(
        {
            id               => '',
            version_id       => '',
            name             => $pkg_name,
            package_password => ''
        }
    );

    ok( !$package->log_to_server, 'Log to SQL Server should be disable' );
    ok( defined( $package->get_log_file ), 'Log to flat file is enable' );
    ok( !$package->use_event_log,
        'Write completation status on Event log should be disable' );
    ok(
        $package->use_explicit_global_vars,
        'Global variable are explicit declared'
    );
    cmp_ok( $package->count_connections, '>=', 2,
        'Package must have at least two connections' );
    cmp_ok( $package->count_datapumps, '>=', 1,
        'Package must have at least one datapump task' );

}

sub several_apps {

    my $app = Win32::SqlServer::DTS::Application->new( $xml->XMLin(XML_FILE) );

    my $package = $app->get_db_package(
        {
            id               => '',
            version_id       => '',
            name             => $pkg_name,
            package_password => ''
        }
    );

    ok( !$package->log_to_server, 'Log to SQL Server should be disable' );
    ok( defined( $package->get_log_file ), 'Log to flat file is enable' );
    ok( !$package->use_event_log,
        'Write completation status on Event log should be disable' );
    ok(
        $package->use_explicit_global_vars,
        'Global variable are explicit declared'
    );
    cmp_ok( $package->count_connections, '>=', 2,
        'Package must have at least two connections' );
    cmp_ok( $package->count_datapumps, '>=', 1,
        'Package must have at least one datapump task' );

}
