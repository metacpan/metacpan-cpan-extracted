use strict;

use utf8;
use Bit::Vector;
use Test::More;
use Test::BinaryData;
use Thrift::XS;

plan tests => 61;

my $xst = Thrift::XS::MemoryBuffer->new;
my $xsp = Thrift::XS::CompactProtocol->new($xst);

# Test that getTransport works
{
    my $t = $xsp->getTransport();
    isa_ok($t, 'Thrift::XS::MemoryBuffer', "getTransport ok");
}

my $test = sub {
    my ($method, $args, $expect) = @_;
    $xsp->$method( @{$args} );
    
    # Hack to avoid wide char warnings
    if (utf8::is_utf8($args->[0])) {
        utf8::encode($args->[0]);
    }
    
    is_binary( $xst->read(999), $expect, "$method ok (" . join(', ', @{$args}) . ")" );
};

# Write tests
{
    $test->('writeMessageBegin' => [ 'login', TMessageType::CALL, 12345 ] => pack('H*', '8221b960056c6f67696e'));
    my $utf8 = 'русский';
    $test->('writeMessageBegin' => [ $utf8, TMessageType::REPLY, 1 ] => pack('H*', '8241010ed180d183d181d181d0bad0b8d0b9'));
    
    # Tests for special field/bool handling
    $test->('writeFieldBegin' => [ 'key', TType::STRING, 1 ] => pack('H*', '18'));
    $test->('writeString' => [ 'a mildly long string to test varint: ' . ('x' x 100) ]
        => (pack('H*', '890161206d696c646c79206c6f6e6720737472696e6720746f207465737420766172696e743a20') . pack('H*', '78' x 100)));
    $test->('writeFieldEnd' => [] => '');
    
    $test->('writeFieldBegin' => [ 'bool', TType::BOOL, 2 ] => ''); # No output from bool field begin
    $test->('writeBool' => [ 1 ] => pack('H*', '11'));
    $test->('writeFieldEnd' => [] => '');
    
    $test->('writeFieldBegin' => [ 'bool', TType::BOOL, 3 ] => ''); # No output from bool field begin
    $test->('writeBool' => [ 0 ] => pack('H*', '12'));
    $test->('writeFieldEnd' => [] => '');
    
    $test->('writeFieldStop' => [] => pack('H*', 0));

    $test->('writeStructBegin' => [ 'foo' ] => '');
    $test->('writeStructEnd' => [] => '');
    
    $test->('writeMapBegin' => [ TType::STRING, TType::LIST, 42 ] => pack('H*', '2a89'));
    $test->('writeMapBegin' => [ TType::STRING, TType::LIST, 0 ] => pack('H*', 0));
    
    $test->('writeListBegin' => [ TType::STRUCT, 14 ] => pack('H*', 'ec'));
    $test->('writeListBegin' => [ TType::STRING, 200 ] => pack('H*', 'f8c801'));
    
    $test->('writeSetBegin' => [ TType::I32, 8 ] => pack('H*', '85'));
    
    $test->('writeByte' => [ 50 ] => pack('H*', '32'));
    
    $test->('writeI16' => [ 65000 ] => pack('H*', 'd0f707'));
    $test->('writeI16' => [ -42 ] => pack('H*', '53'));
    
    $test->('writeI32' => [ 1 << 30 ] => pack('H*', '8080808008'));
    $test->('writeI32' => [ -60124235 ] => pack('H*', '95b1ab39'));
    
    # writeI64 supports both strings and numbers. >32-bit values are strings so they work on 32-bit systems
    $test->('writeI64' => [ 1234567 ] => pack('H*', '8eda9601'));
    $test->('writeI64' => [ "1099511627776" ] => pack('H*', '808080808040'));
    $test->('writeI64' => [ "-235412341332" ] => pack('H*', 'a789dafad90d'));
    $test->('writeI64' => [ "-169599668584448" ] => pack('H*', 'ffffffffff8f4d'));
    
    $test->('writeDouble' => [ 3.14159 ] => pack('H*', '6e861bf0f9210940'));
    
    $test->('writeString' => [ 'This is a test' ] => pack('H*', '0e5468697320697320612074657374'));
    $utf8 = 'This is a unicode test with русский';
    $test->('writeString' => [ $utf8 ] => pack('H*', '2a54686973206973206120756e69636f64652074657374207769746820d180d183d181d181d0bad0b8d0b9'));
    
    # Test for writeString of binary data that looks like UTF-8 (reported by Aaron Turner)
    print "# testing writeString of 640 as 64-bit int\n";
    my $vec = Bit::Vector->new_Dec(64, 640);
    my $long_int = pack('NN', $vec->Chunk_Read(32, 32), $vec->Chunk_Read(32, 0));
    $test->('writeString' => [ $long_int ] => pack('H*', '080000000000000280'));
}

# Read tests
{
    my ($name, $type, $seqid);
    $xsp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
    $xsp->readMessageBegin(\$name, \$type, \$seqid);
    is($name, 'login русский', "readMessageBegin name ok");
    is($type, TMessageType::CALL, "readMessageBegin type ok");
    is($seqid, 12345, "readMessageBegin seqid ok");
}

{
    my $name;
    $xsp->writeStructBegin('foo');
    $xsp->readStructBegin(\$name);
    is($name, '', "readStructBegin name ok");
}

{ 
    my ($name, $type, $id);   
    $xsp->writeFieldBegin('start', TType::STRING, 2600);
    $xsp->readFieldBegin(\$name, \$type, \$id);
    # name is not returned
    is($type, TType::STRING, "readFieldBegin fieldtype ok");
    is($id, 2600, "readFieldBegin fieldid ok");
}

{ 
    my ($keytype, $valtype, $size);
    $xsp->writeMapBegin(TType::STRING, TType::LIST, 42);
    $xsp->readMapBegin(\$keytype, \$valtype, \$size);
    is($keytype, TType::STRING, "readMapBegin keytype ok");
    is($valtype, TType::LIST, "readMapBegin valtype ok");
    is($size, 42, "readMapBegin size ok");
}

{   
    my ($elemtype, $size);
    $xsp->writeListBegin(TType::STRUCT, 12345);
    $xsp->readListBegin(\$elemtype, \$size);
    is($elemtype, TType::STRUCT, "readListBegin elemtype ok");
    is($size, 12345, "readListBegin size ok");
}

{   
    my ($elemtype, $size);
    $xsp->writeSetBegin(TType::I16, 12345);
    $xsp->readSetBegin(\$elemtype, \$size);
    is($elemtype, TType::I16, "readSetBegin elemtype ok");
    is($size, 12345, "readSetBegin size ok");
}

{
    my $value;
    $xsp->writeBool('true');
    $xsp->readBool(\$value);
    is($value, 1, "readBool true ok");
    
    $xsp->writeBool(0);
    $xsp->readBool(\$value);
    is($value, 0, "readBool false ok");
}

{
    my $value;
    $xsp->writeByte(100);
    $xsp->readByte(\$value);
    is($value, 100, "readByte ok");
}

{
    my $value;
    $xsp->writeI16(65534);
    $xsp->readI16(\$value);
    is($value, 65534, "readI16 ok");
}

{
    my $value;
    $xsp->writeI32(1024 * 1024);
    $xsp->readI32(\$value);
    is($value, 1024 * 1024, "readI32 ok");
}

{
    my $value;
    my $i64 = "-169599668584448";
    $xsp->writeI64($i64);
    $xsp->readI64(\$value);
    is($value, $i64, "readI64 ok");
}

{
    my $value;
    $xsp->writeDouble(-3.14159);
    $xsp->readDouble(\$value);
    is(sprintf("%.5f", $value), "-3.14159", "readDouble ok");
}

{
    my $value;
    $xsp->writeString('This is a unicode test with русский');
    $xsp->readString(\$value);
    is($value, 'This is a unicode test with русский', "readString with unicode ok");
}

# Test a real struct/field group from Cassandra
{
    $xsp->resetState();
    
    $xsp->writeStructBegin('SliceRange');
    $xsp->writeFieldBegin('start', TType::STRING, 1);
    $xsp->writeString(1);
    $xsp->writeFieldEnd();
    $xsp->writeFieldBegin('finish', TType::STRING, 2);
    $xsp->writeString(1000);
    $xsp->writeFieldEnd();
    $xsp->writeFieldBegin('reversed', TType::BOOL, 3);
    $xsp->writeBool(0);
    $xsp->writeFieldEnd();
    $xsp->writeFieldBegin('count', TType::I32, 4);
    $xsp->writeI32(100);
    $xsp->writeFieldEnd();
    $xsp->writeFieldStop();
    $xsp->writeStructEnd();
    
    my $fname;
    my $ftype = 0;
    my $fid   = 0;
    my $tmp = {};
    $xsp->readStructBegin(\$fname);
    while (1) 
    {
      $xsp->readFieldBegin(\$fname, \$ftype, \$fid);
      if ($ftype == TType::STOP) {
        last;
      }
      SWITCH: for($fid)
      {
        /^1$/ && do{      if ($ftype == TType::STRING) {
          $xsp->readString(\$tmp->{start});
        } else {
          $xsp->skip($ftype);
        }
        last; };
        /^2$/ && do{      if ($ftype == TType::STRING) {
          $xsp->readString(\$tmp->{finish});
        } else {
          $xsp->skip($ftype);
        }
        last; };
        /^3$/ && do{      if ($ftype == TType::BOOL) {
          $xsp->readBool(\$tmp->{reversed});
        } else {
          $xsp->skip($ftype);
        }
        last; };
        /^4$/ && do{      if ($ftype == TType::I32) {
          $xsp->readI32(\$tmp->{count});
        } else {
          $xsp->skip($ftype);
        }
        last; };
          $xsp->skip($ftype);
      }
      $xsp->readFieldEnd();
    }
    $xsp->readStructEnd();
    
    is( $tmp->{start}, 1, "struct/field start=1 ok" );
    is( $tmp->{finish}, 1000, "struct/field finish=1000 ok" );
    is( $tmp->{reversed}, 0, "struct/field reversed=0 ok" );
    is( $tmp->{count}, 100, "struct/field count=100 ok" );
}

# Struct/Map/String code from Cassandra
{
    my $credentials = {
        user1 => 'pass1',
        user2 => 'pass2',
    };
    
    $xsp->resetState();
    
    $xsp->writeStructBegin('AuthenticationRequest');
    $xsp->writeFieldBegin('credentials', TType::MAP, 1);
    $xsp->writeMapBegin(TType::STRING, TType::STRING, scalar(keys %{$credentials}));
    while (my ($k, $v) = each %{$credentials}) {
        $xsp->writeString($k);
        $xsp->writeString($v);
    }
    $xsp->writeMapEnd();
    $xsp->writeFieldEnd();
    $xsp->writeFieldStop();
    $xsp->writeStructEnd();
    
    my $creds;
    my $fname;
    my $ftype = 0;
    my $fid   = 0;
    $xsp->readStructBegin(\$fname);
    while (1) 
    {
      $xsp->readFieldBegin(\$fname, \$ftype, \$fid);
      if ($ftype == TType::STOP) {
        last;
      }
      SWITCH: for($fid)
      {
        /^1$/ && do{      if ($ftype == TType::MAP) {
          {
            my $_size = 0;
            $creds = {};
            my $_ktype = 0;
            my $_vtype = 0;
            $xsp->readMapBegin(\$_ktype, \$_vtype, \$_size);
            for (my $_i = 0; $_i < $_size; ++$_i)
            {
              my $key = '';
              my $val = '';
              $xsp->readString(\$key);
              $xsp->readString(\$val);
              $creds->{$key} = $val;
            }
            $xsp->readMapEnd();
          }
        } else {
          $xsp->skip($ftype);
        }
        last; };
          $xsp->skip($ftype);
      }
      $xsp->readFieldEnd();
    }
    $xsp->readStructEnd();
    
    is( $creds->{user1}, 'pass1', 'struct map string 1 ok' );
    is( $creds->{user2}, 'pass2', 'struct map string 2 ok' );
}

# map<string, list<string>> describe_schema_versions()
{    
    my $data = {
        foo => [ 1, 2, 3 ],
        bar => [ 4, 5, 6 ],
    };
    
    $xsp->resetState();
    
    $xsp->writeStructBegin('Cassandra_describe_schema_versions_result');
    $xsp->writeFieldBegin('success', TType::MAP, 0);
    $xsp->writeMapBegin(TType::STRING, TType::LIST, scalar(keys %{$data}));
    while ( my ($k, $v) = each %{$data} ) {
        $xsp->writeString($k);
        $xsp->writeListBegin(TType::STRING, scalar(@{$v}));
        foreach my $s (@{$v}) {
            $xsp->writeString($s);
        }
        $xsp->writeListEnd();
    }
    $xsp->writeMapEnd();
    $xsp->writeFieldEnd();
    $xsp->writeFieldStop();
    $xsp->writeStructEnd();
    
    my $fname;
    my $ftype = 0;
    my $fid   = 0;
    my $read;
    $xsp->readStructBegin(\$fname);
    while (1) 
    {
      $xsp->readFieldBegin(\$fname, \$ftype, \$fid);
      if ($ftype == TType::STOP) {
        last;
      }
      SWITCH: for($fid)
      {
        /^0$/ && do{      if ($ftype == TType::MAP) {
            my $size = 0;
            $read = {};
            my $ktype = 0;
            my $vtype = 0;
            $xsp->readMapBegin(\$ktype, \$vtype, \$size);
            for (my $i = 0; $i < $size; ++$i)
            {
              my $key = '';
              my $val = [];
              $xsp->readString(\$key);
              my $lsize = 0;
              my $list = [];
              my $etype = 0;
              $xsp->readListBegin(\$etype, \$lsize);
              for (my $j = 0; $j < $lsize; ++$j)
              {
                my $str = undef;
                $xsp->readString(\$str);
                push(@{$list},$str);
              }
              $xsp->readListEnd();
              $read->{$key} = $list;
            }
            $xsp->readMapEnd();
        } else {
          $xsp->skip($ftype);
        }
        last; };
      }
      $xsp->readFieldEnd();
    }
    $xsp->readStructEnd();
    
    is_deeply($read, $data, "map<string, list<string>> ok");
}
