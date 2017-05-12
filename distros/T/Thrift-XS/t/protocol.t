use strict;

use utf8;
use Bit::Vector;
use Test::More;
use Test::BinaryData;
use Thrift::XS;
use Thrift::MemoryBuffer;
use Thrift::BinaryProtocol;

plan tests => 80;

# Tests compare pure Perl output with XS output
my $xst = Thrift::XS::MemoryBuffer->new;
my $xsp = Thrift::XS::BinaryProtocol->new($xst);

my $ppt = Thrift::MemoryBuffer->new;
my $ppp = Thrift::BinaryProtocol->new($ppt);

# Test that getTransport works
{
    my $t = $xsp->getTransport();
    isa_ok($t, 'Thrift::XS::MemoryBuffer', "getTransport ok");
}

my $test = sub {
    my $method = shift;
    my $xs_count = $xsp->$method(@_);
    my $pl_count = $ppp->$method(@_);
    
    # Hack to avoid wide char warnings
    if (utf8::is_utf8($_[0])) {
        utf8::encode($_[0]);
    }
    
    my $x = $xst->read(999);
    my $p = $ppt->read(999);
    
    is($xs_count, $pl_count, "$method byte counts ok");
    is_binary( $x, $p, "$method ok (" . join(', ', @_) . ")" );
};

# Write tests
{
    $test->('writeMessageBegin' => 'login', TMessageType::CALL, 12345);
    my $utf8 = 'русский';
    $test->('writeMessageBegin' => $utf8, TMessageType::REPLY, 1);
    $test->('writeFieldBegin' => 'start', TType::STRING, 1);
    $test->('writeFieldStop');
    $test->('writeMapBegin' => TType::STRING, TType::LIST, 42);
    $test->('writeListBegin' => TType::STRUCT, 12345678);
    $test->('writeSetBegin' => TType::I32, 8);
    $test->('writeBool' => 1);
    $test->('writeBool' => 0);
    $test->('writeByte' => 50);
    $test->('writeI16' => 65000);
    $test->('writeI16' => -42);
    $test->('writeI32' => 1 << 30);
    $test->('writeI32' => -60);
    $test->('writeI64' => 1 << 40);
    $test->('writeI64' => -235412341332);
    $test->('writeDouble' => 3.14159);
    $test->('writeString' => 'This is a test');
    $utf8 = 'This is a unicode test with русский';
    $test->('writeString' => $utf8);
    
    # Tests for writeString of binary data that looks like UTF-8 (reported by Aaron Turner)
    for my $value (639, 640) {
        print "# testing writeString of $value as 64-bit int\n";
        my $vec = Bit::Vector->new_Dec(64, "$value");
        my $long_int = pack('NN', $vec->Chunk_Read(32, 32), $vec->Chunk_Read(32, 0));
        $test->('writeString' => $long_int);
    }
}

# Read tests
{
    my ($name, $type, $seqid);
    my $written = $xsp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
    my $read = $xsp->readMessageBegin(\$name, \$type, \$seqid);
    is($name, 'login русский', "readMessageBegin name ok");
    is($type, TMessageType::CALL, "readMessageBegin type ok");
    is($seqid, 12345, "readMessageBegin seqid ok");
    is($read, $written, "readMessageBegin read and written byte-count ok");
}

{
    my $name;
    my $written = $xsp->writeStructBegin('foo');
    my $read = $xsp->readStructBegin(\$name);
    is($name, '', "readStructBegin name ok");
    is($read, $written, "readStructBegin read and written byte-count ok");
}

{
    my ($name, $type, $id);   
    my $written = $xsp->writeFieldBegin('start', TType::STRING, 2600);
    my $read = $xsp->readFieldBegin(\$name, \$type, \$id);
    # name is not returned
    is($type, TType::STRING, "readFieldBegin fieldtype ok");
    is($id, 2600, "readFieldBegin fieldid ok");
    is($read, $written, "readFieldBegin read and written byte-count ok");
}

{
    my ($keytype, $valtype, $size);
    my $written = $xsp->writeMapBegin(TType::STRING, TType::LIST, 42);
    my $read = $xsp->readMapBegin(\$keytype, \$valtype, \$size);
    is($keytype, TType::STRING, "readMapBegin keytype ok");
    is($valtype, TType::LIST, "readMapBegin valtype ok");
    is($size, 42, "readMapBegin size ok");
    is($read, $written, "readMapBegin read and written byte-count ok");
}

{
    my ($elemtype, $size);
    my $written = $xsp->writeListBegin(TType::STRUCT, 12345);
    my $read = $xsp->readListBegin(\$elemtype, \$size);
    is($elemtype, TType::STRUCT, "readListBegin elemtype ok");
    is($size, 12345, "readListBegin size ok");
    is($read, $written, "readListBegin read and written byte-count ok");
}

{
    my ($elemtype, $size);
    my $written = $xsp->writeSetBegin(TType::I16, 12345);
    my $read = $xsp->readSetBegin(\$elemtype, \$size);
    is($elemtype, TType::I16, "readSetBegin elemtype ok");
    is($size, 12345, "readSetBegin size ok");
    is($read, $written, "readSetBegin read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeBool('true');
    my $read = $xsp->readBool(\$value);
    is($value, 1, "readBool true ok");
    is($read, $written, "readBool true read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeBool(0);
    my $read = $xsp->readBool(\$value);
    is($value, 0, "readBool false ok");
    is($read, $written, "readBool false read and written byte-count ok");
}


{
    my $value;
    my $written = $xsp->writeByte(100);
    my $read = $xsp->readByte(\$value);
    is($value, 100, "readByte ok");
    is($read, $written, "readByte read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeI16(65534);
    my $read = $xsp->readI16(\$value);
    is($value, 65534, "readI16 ok");
    is($read, $written, "readI16 read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeI32(1024 * 1024);
    my $read = $xsp->readI32(\$value);
    is($value, 1024 * 1024, "readI32 ok");
    is($read, $written, "readI32 read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeI64((1 << 37) * -1234);
    my $read = $xsp->readI64(\$value);
    is($value, (1 << 37) * -1234, "readI64 ok");
    is($read, $written, "readI64 read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeDouble(-3.14159);
    my $read = $xsp->readDouble(\$value);
    is(sprintf("%.5f", $value), "-3.14159", "readDouble ok");
    is($read, $written, "readDouble read and written byte-count ok");
}

{
    my $value;
    my $written = $xsp->writeString('This is a unicode test with русский');
    my $read = $xsp->readString(\$value);
    is($value, 'This is a unicode test with русский', "readString with unicode ok");
    is($read, $written, "readString with unicode read and written byte-count ok");
}

{
    my $str = 'This is a unicode test with русский';
    my $value;
    my $written = $xsp->writeString($str);
    my $read_len = $xsp->readI32(\$value); # skip writeString len
    my $read_string = $xsp->readStringBody(\$value, bytes::length($str));
    is($value, $str, "readStringBody with unicode ok");
    is($read_len + $read_string, $written, "readStringBody with unicode read and written byte-count ok");
}
