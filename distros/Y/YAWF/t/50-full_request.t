#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use lib 't/50-files';

use Test::More     tests => 34;

our %returns;

my $dbfile = 't/50-files/db';

unlink $dbfile;    # Clean up an old copy

use_ok('DBI');
my $dbh =
  DBI->connect( "dbi:SQLite:dbname=$dbfile", 'none', 'none',
    { AutoCommit => 1 } );
ok( defined($dbh), 'Create environment: create database' );
ok(
    $dbh->do(
'CREATE TABLE footab(id INTEGER NOT NULL PRIMARY KEY,bartext VARCHAR(32) NULL)'
    ),
    'Create environment: create table'
);
ok(
    $dbh->do(
        'INSERT INTO footab(id,bartext) VALUES(1,"123456789xx01234567890")'),
    'Create environment: add data row 1'
);
ok(
    $dbh->do(
        'INSERT INTO footab(id,bartext) VALUES(2,"1x3x5x7x9xxx1x3x5x7x9x")'),
    'Create environment: add data row 2'
);
ok( $dbh->do('INSERT INTO footab(id,bartext) VALUES(5,"9,8,7,6,5,4,3,2,1,0")'),
    'Create environment: add data row 3' );
ok( $dbh->disconnect, 'Create environment: finish database' );

use_ok('YAWF');
use_ok('YAWF::Request');

# Create environment for CGI:
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'perl=5&yawf=true';

my $request = YAWF::Request->new(
    domain   => 'test.foo.bar',
    uri      => '/home.page.html',
    args_GET => $ENV{QUERY_STRING},
    method   => $ENV{REQUEST_METHOD},

    #                    headers      => {},
    documentroot => 't/50-files',
    error        => sub {
        $main::returns{error} .= join( '', @_ ) . "\n";
        return 1;
    },
    send_header => sub {
        $main::returns{header} ||= [];
        push @{ $main::returns{header} }, join( '', @_ );
        return 1;
    },
    send_status => sub {
        $main::returns{status} .= join( '', @_ );
        return 1;
    },
    send_body => sub {
        $main::returns{body} .= join( '', @_ );
        return 1;
    },
);
ok( defined($request), 'Create request' );

is( ref($request),          'YAWF::Request',   'Request type' );
is( $request->domain,       'test.foo.bar',    'Domain' );
is( $request->uri,          '/home.page.html', 'Domain' );
is( $request->method,       'GET',             'Method' );
is( $request->documentroot, 't/50-files',      'Document root' );
is( $returns{error},        undef,             'Check error' );

# Check sync
is( $request->yawf,  YAWF->SINGLETON,                'YAWF Singleton' );
is( YAWF->SINGLETON, YAWF->SINGLETON->request->yawf, 'YAWF in request' );
is( YAWF->SINGLETON, YAWF->SINGLETON->reply->yawf,   'YAWF in reply' );
is(
    YAWF->SINGLETON,
    YAWF->SINGLETON->reply->data->{yawf},
    'YAWF in reply data'
);

# Config tests
my $config = $request->yawf->config;
is( ref($config),           'YAWF::Config',         'Config object' );
is( $config->domain,        'www.foo.bar',          'config domain' );
is( $config->handlerprefix, 'Test50',               'config handler prefix' );
is( $config->template_dir,  't/50-files/templates', 'config template dir' );
ok( defined( $config->database ), 'config database' );
is(
    $config->database->{dbi},
    'dbi:SQLite:dbname=t/50-files/db',
    'config database dbi'
);
is( $config->database->{database}, $dbfile,      'config database name' );
is( $config->database->{username}, 'none',       'config database username' );
is( $config->database->{password}, 'none',       'config database password' );
is( $config->database->{class},    'Test50::DB', 'config database base class' );
is( YAWF->SINGLETON->reply->data->{yawf}->config->domain,
    'www.foo.bar', 'domain reply data' );

is( $request->run, 200, 'Process the request' );

my $expected_body = <<_EOT_;
(testdata=1)
(domain=www.foo.bar)
(footab=1:123456789xx01234567890)
(foolist[1]=123456789xx01234567890)
(foolist[2]=1x3x5x7x9xxx1x3x5x7x9x)
(foolist[5]=9,8,7,6,5,4,3,2,1,0)
_EOT_
is( $returns{error}, undef,          'errors' );
is( $returns{body},  $expected_body, 'body' );
