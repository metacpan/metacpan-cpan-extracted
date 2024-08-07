use Test::More;
use Test::Fatal;
use File::Temp qw[:POSIX];
use File::Slurp;

BEGIN {
    use_ok( 'Zonemaster::Engine' );
    use_ok( 'Zonemaster::Engine::Test' );
    use_ok( 'Zonemaster::Engine::Nameserver' );
    use_ok( 'Zonemaster::Engine::Exception' );
}

is( exception { Zonemaster::Engine->reset(); }, undef, 'No crash on instant reset.');

my $datafile = q{t/zonemaster.data};
if ( not $ENV{ZONEMASTER_RECORD} ) {
    die q{Stored data file missing} if not -r $datafile;
    Zonemaster::Engine::Nameserver->restore( $datafile );
    Zonemaster::Engine::Profile->effective->set( q{no_network}, 1 );
}

my ($json, $profile_tmp);
$json        = read_file( 't/profiles/Test-all.json' );
$profile_tmp = Zonemaster::Engine::Profile->from_json( $json );
Zonemaster::Engine::Profile->effective->merge( $profile_tmp );
$json        = read_file( 't/profiles/Test-all-levels.json' );
$profile_tmp = Zonemaster::Engine::Profile->from_json( $json );
Zonemaster::Engine::Profile->effective->merge( $profile_tmp );

isa_ok( Zonemaster::Engine->logger, 'Zonemaster::Engine::Logger' );
isa_ok( Zonemaster::Engine::Profile->effective, 'Zonemaster::Engine::Profile' );

my %module = map { $_ => 1 } Zonemaster::Engine::Test->modules;

ok( $module{Consistency},  'Consistency' );
ok( $module{Delegation},   'Delegation' );
ok( $module{Syntax},       'Syntax' );
ok( $module{Connectivity}, 'Connectivity' );

my %methods = Zonemaster::Engine->all_methods;
ok( exists( $methods{Basic} ), 'all_methods' );

my @tags = Zonemaster::Engine->all_tags;
ok( ( grep { /BASIC:B02_AUTH_RESPONSE_SOA/ } @tags ), 'all_tags' );

my $dependency_version = 0;
my $global_version     = 0;
%module = ();
%end    = ();
Zonemaster::Engine->logger->callback(
    sub {
        my ( $e ) = shift;

        if ( $e->tag eq 'MODULE_VERSION' ) {
            $module{ $e->args->{module} } = $e->args->{version};
        }

        if ( $e->tag eq 'MODULE_END' ) {
            $end{ $e->args->{module} } = 1;
        }

        if ( $e->tag eq 'GLOBAL_VERSION' ) {
            $global_version = $e->args->{version};
        }

        if ( $e->tag eq 'DEPENDENCY_VERSION' ) {
            $dependency_version = 1;
        }

    }
);

my @results = Zonemaster::Engine->test_zone( 'nic.se' );

ok( $global_version,     "Global version: $global_version" );
ok( $dependency_version, 'At least one dependency version logged' );

ok( $module{'Zonemaster::Engine::Test::Address'},      'Zonemaster::Engine::Test::Address did run.' );
ok( $module{'Zonemaster::Engine::Test::Basic'},        'Zonemaster::Engine::Test::Basic did run.' );
ok( $module{'Zonemaster::Engine::Test::Connectivity'}, 'Zonemaster::Engine::Test::Connectivity did run.' );
ok( $module{'Zonemaster::Engine::Test::Consistency'},  'Zonemaster::Engine::Test::Consistency did run.' );
ok( $module{'Zonemaster::Engine::Test::DNSSEC'},       'Zonemaster::Engine::Test::DNSSEC did run.' );
ok( $module{'Zonemaster::Engine::Test::Delegation'},   'Zonemaster::Engine::Test::Delegation did run.' );
ok( $module{'Zonemaster::Engine::Test::Nameserver'},   'Zonemaster::Engine::Test::Nameserver did run.' );
ok( $module{'Zonemaster::Engine::Test::Syntax'},       'Zonemaster::Engine::Test::Syntax did run.' );
ok( $module{'Zonemaster::Engine::Test::Zone'},         'Zonemaster::Engine::Test::Zone did run.' );

ok( $end{'Zonemaster::Engine::Test::Address'},      'Zonemaster::Engine::Test::Address did end.' );
ok( $end{'Zonemaster::Engine::Test::Basic'},        'Zonemaster::Engine::Test::Basic did end.' );
ok( $end{'Zonemaster::Engine::Test::Connectivity'}, 'Zonemaster::Engine::Test::Connectivity did end.' );
ok( $end{'Zonemaster::Engine::Test::Consistency'},  'Zonemaster::Engine::Test::Consistency did end.' );
ok( $end{'Zonemaster::Engine::Test::DNSSEC'},       'Zonemaster::Engine::Test::DNSSEC did end.' );
ok( $end{'Zonemaster::Engine::Test::Delegation'},   'Zonemaster::Engine::Test::Delegation did end.' );
ok( $end{'Zonemaster::Engine::Test::Nameserver'},   'Zonemaster::Engine::Test::Nameserver did end.' );
ok( $end{'Zonemaster::Engine::Test::Syntax'},       'Zonemaster::Engine::Test::Syntax did end.' );
ok( $end{'Zonemaster::Engine::Test::Zone'},         'Zonemaster::Engine::Test::Zone did end.' );

my $filename = tmpnam();
Zonemaster::Engine->save_cache( $filename );
my $save_entry = Zonemaster::Engine->logger->entries->[-1];
Zonemaster::Engine->preload_cache( $filename );
my $restore_entry = Zonemaster::Engine->logger->entries->[-1];
is( $save_entry->tag,             'SAVED_NS_CACHE',    'Saving worked.' );
is( $save_entry->args->{file},    $filename,           'To the right file name.' );
is( $restore_entry->tag,          'RESTORED_NS_CACHE', 'Restoring worked.' );
is( $restore_entry->args->{file}, $filename,           'From the right file name.' );
unlink( $filename );

Zonemaster::Engine->test_module( 'gurksallad', 'nic.se' );
is( Zonemaster::Engine->logger->entries->[-1]->tag, 'UNKNOWN_MODULE', 'Proper message for unknown module' );

Zonemaster::Engine->test_method( 'gurksallad', 'nic.se' );
is( Zonemaster::Engine->logger->entries->[-1]->tag, 'UNKNOWN_MODULE', 'Proper message for unknown module' );

Zonemaster::Engine->test_method( 'basic', 'basic17' );
is( Zonemaster::Engine->logger->entries->[-1]->tag, 'UNKNOWN_METHOD', 'Proper message for unknown method' );

# Test exceptions in callbacks
Zonemaster::Engine->logger->callback(
    sub {
        my ( $e ) = @_;
        return if ( $e->module eq 'SYSTEM' or $e->module eq 'BASIC' );
        die Zonemaster::Engine::Exception->new( { message => 'canary' } );
    }
);
isa_ok( exception { Zonemaster::Engine->test_zone( 'nic.se' ) }, 'Zonemaster::Engine::Exception' );
isa_ok( exception { Zonemaster::Engine->test_module( 'SyNtAx', 'nic.se' ) }, 'Zonemaster::Engine::Exception' );
isa_ok( exception { Zonemaster::Engine->test_method( 'Syntax', 'syntax01', 'nic.se' ) }, 'Zonemaster::Engine::Exception' );
Zonemaster::Engine->logger->callback( undef );

Zonemaster::Engine::Profile->effective->set( q{net.ipv4}, 0 );
Zonemaster::Engine::Profile->effective->set( q{net.ipv6}, 0 );
my ( $msg ) = Zonemaster::Engine->test_zone( 'nic.se' );
ok( !!$msg, 'Got a message.' );
is( $msg->tag, 'NO_NETWORK', 'It is the right message.' );

( $msg ) = Zonemaster::Engine->test_module( 'Basic', 'nic.se' );
ok( !!$msg, 'Got a message.' );
is( $msg->tag, 'NO_NETWORK', 'It is the right message.' );

( $msg ) = Zonemaster::Engine->test_method( 'Basic', 'basic01', 'nic.se' );
ok( !!$msg, 'Got a message.' );
is( $msg->tag, 'NO_NETWORK', 'It is the right message.' );
Zonemaster::Engine::Profile->effective->set( q{net.ipv4}, 1 );
Zonemaster::Engine::Profile->effective->set( q{net.ipv6}, 1 );

if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Engine::Nameserver->save( $datafile );
}

ok( @{ Zonemaster::Engine->logger->entries } > 0,                        'There are log entries' );
ok( scalar( keys( %Zonemaster::Engine::Nameserver::object_cache ) ) > 0, 'There are things in the object cache' );
Zonemaster::Engine->reset;
ok( @{ Zonemaster::Engine->logger->entries } == 0,                        'There are no log entries' );
ok( scalar( keys( %Zonemaster::Engine::Nameserver::object_cache ) ) == 0, 'The object cache is empty' );
ok( scalar( keys( %Zonemaster::Engine::Nameserver::Cache::object_cache ) ) == 0, 'The packet cache is empty' );

done_testing;
