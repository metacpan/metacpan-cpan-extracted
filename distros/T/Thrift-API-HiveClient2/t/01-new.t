use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;


use Thrift::API::HiveClient2;

my $HIVEHOST = $ENV{HIVEHOST};
my $HIVEPORT = $ENV{HIVEPORT} || 10_000;

plan skip_all => "Set up HiveServer2 host with \$ENV{HIVEHOST}" 
    if !$HIVEHOST;
plan tests => 6;

my $obj;

ok( ref( $obj = Thrift::API::HiveClient2->new( host => $HIVEHOST, port => $HIVEPORT ) ) =~ /Thrift/,
    "Default client" );

SKIP: {
    skip "connect: set HIVEHOST (and optionally HIVEPORT) environment variable(s)", 1
        if !$HIVEHOST;
    ok( eval { $obj->connect }, "Connecting to server");
}

ok( ref( $obj = Thrift::API::HiveClient2->new( host => $HIVEHOST, port => $HIVEPORT, use_xs => 0 ) )
        !~ /XS/,
    "Client with XS disabled"
);

SKIP: {
    skip "connection test", 1 if !$HIVEHOST;
    ok( eval { $obj->connect }, "Connecting to server");
}

SKIP: {
    skip "Thrift::XS::BinaryProtocol non functional with BufferedTransport", 2;
    skip "Thrift::XS::BinaryProtocol not installed", 2
        if !eval { require Thrift::XS::BinaryProtocol };
    ok( $obj = ref(Thrift::API::HiveClient2->new(
                host   => $HIVEHOST,
                port   => $HIVEPORT,
                use_xs => 1
            )
            ) =~ /XS/,
        "Client with XS enabled"
    );
    ok( eval { $obj->connect }, "Connecting to server");
}

__END__

use Data::Dumper;
my $client = Thrift::API::HiveClient2->new( host => $HIVEHOST, port => $HIVEPORT );
$client->connect;
my $handle = $client->execute('SHOW TABLES');
print Dumper($client->fetch($handle, 10));
