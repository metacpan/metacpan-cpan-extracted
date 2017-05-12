use strict;

use Test::More;
use Thrift::XS;

plan tests => 8;

{
    my $mb = Thrift::XS::MemoryBuffer->new();
    
    is( $mb->read(64), "", "empty read ok" );
    
    # test write/read
    $mb->write("test");
    is( $mb->available, 4, "available() ok" );
    is( $mb->read(4), "test", "write/read 4 ok" );

    # test unicode write/read
    use utf8;
    my $utf8 = "русский";
    my $utf8b = $utf8;
    utf8::encode($utf8b);
    $mb->write($utf8);
    is( $mb->read(128), $utf8b, "unicode write/read ok" );
    
    eval { $mb->readAll(16) };
    is( ref $@, "TTransportException", "readAll(16) threw a TTransportException ok" );
    is( $@->{code}, 0, "TTransportException code is 0 ok" );
    is( $@->{message}, "Attempt to readAll(16) found only 0 available", "TTransportException message ok" );
    
    $mb->write( pack 'N', 12345 );
    is( unpack('N', $mb->readAll(4)), 12345, "write/readAll 32-bit int ok" );
}
