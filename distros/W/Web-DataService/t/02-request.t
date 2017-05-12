
use Test::More tests => 13;

# Untaint $^X and the path.  Is there a better way to do this?  I am assuming that
# since this is a test script we do not have to worry about these being compromised.

$^X =~ /(.*)/;
my $perl = $1;

$ENV{PATH} =~ /(.*)/;
$ENV{PATH} = $1;

$ENV{DANCER_APPDIR} = '.';
$ENV{WDS_QUIET} = 1;

my ($result);

eval {
    $result = `cd files; $perl bin/dataservice.pl GET /data1.0/single.json 'state=WI'`;
};

ok( !$@, 'invocation: single' ) or diag( "    message was: $@" );

unless ( $result )
{
    BAIL_OUT("the data service failed to run.");
}

like( $result, qr{^HTTP/1.0 200 OK}m, 'http header' );

like( $result, qr{^Content-Type: application/json; charset=utf-8}m, 'content type json' );

like( $result, qr{"pop2010":5686986}m, 'data value 1' );

eval {
    $result = `cd files; $perl bin/dataservice.pl GET /data1.0/list.txt 'region=MW&count&datainfo&show=hist'`;
};

ok( !$@, 'invocation: list' ) or diag( "    message was: $@" );

like( $result, qr{^Content-Type: text/plain; charset=utf-8}m, 'content type text' );

like( $result, qr{^"Data Source","U.S. Bureau of the Census"}m, 'data source' );

SKIP: {
    eval { require Template };
    
    skip "Template-Toolkit not installed", 1 if $@;
    
    like( $result, qr{^"Documentation URL","//.*:\d+/data1.0/list_doc.html"}m, 'documentation url' );
}

like( $result, qr{^"Data URL","//.*:\d+/data1.0/list.txt"}m, 'data url' );

like( $result, qr{^"","show","hist"}m, 'parameter "show"' );

like( $result, qr{^"Records Found","16"}m, 'records found' );

like( $result, qr{"pop1900","pop1790"}m, 'optional fields' );

like( $result, qr{^"Michigan","MI","MW","9883635","9938444","9295297","6371766","2420982",""}m, 'data value 2' );
