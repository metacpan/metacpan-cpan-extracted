#!/usr/bin/perl

use strict;

use Benchmark qw(cmpthese);
use Thrift::XS;
use Thrift::MemoryBuffer;
use Thrift::BinaryProtocol;

my $xst = Thrift::XS::MemoryBuffer->new;
my $xsp = Thrift::XS::BinaryProtocol->new($xst);
my $xsc = Thrift::XS::CompactProtocol->new($xst);

my $ppt = Thrift::MemoryBuffer->new;
my $ppp = Thrift::BinaryProtocol->new($ppt);

#                     Rate MemoryBuffer_pp MemoryBuffer_xs
# MemoryBuffer_pp 122530/s              --            -83%
# MemoryBuffer_xs 735583/s            500%              --
#
cmpthese( -5, {
    MemoryBuffer_xs => sub {
        $xst->write( "a" x 256 );
        $xst->readAll(256);
    },
    MemoryBuffer_pp => sub {
        $ppt->write( "a" x 256 );
        $ppt->readAll(256);
        $ppt->resetBuffer(); # Perl version never compacts the buffer without this
    },
} );

#                        Rate BP_MessageBegin_pp CP_MessageBegin_xs BP_MessageBegin_xs
# BP_MessageBegin_pp  21475/s                 --               -91%               -92%
# CP_MessageBegin_xs 249683/s              1063%                 --                -5%
# BP_MessageBegin_xs 261673/s              1118%                 5%                 --                        --
#
cmpthese( -5, {
    BP_MessageBegin_xs => sub {
        my ($name, $type, $seqid);
        $xsp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
        $xsp->readMessageBegin(\$name, \$type, \$seqid);
    },
    CP_MessageBegin_xs => sub {
        my ($name, $type, $seqid);
        $xsc->writeMessageBegin('login русский', TMessageType::CALL, 12345);
        $xsc->readMessageBegin(\$name, \$type, \$seqid);
    },
    BP_MessageBegin_pp => sub {
        my ($name, $type, $seqid);
        $ppp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
        $ppp->readMessageBegin(\$name, \$type, \$seqid);
        $ppt->resetBuffer();
    },
} );

#                       Rate BP_StructBegin_pp CP_StructBegin_xs  BP_StructBegin_xs
# BP_StructBegin_pp   5388/s                --               -84%              -85%
# CP_StructBegin_xs  33619/s              524%                 --               -5%
# BP_StructBegin_xs  35342/s              556%                 5%                --
#
# Note: This benchmark uses a real struct/field group from Cassandra, so Compact can
# properly manage the stack and memory.
#
cmpthese( -5, {
    BP_StructBegin_xs => sub {
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
    },
    CP_StructBegin_xs => sub {
        $xsc->resetState();

        $xsc->writeStructBegin('SliceRange');
        $xsc->writeFieldBegin('start', TType::STRING, 1);
        $xsc->writeString(1);
        $xsc->writeFieldEnd();
        $xsc->writeFieldBegin('finish', TType::STRING, 2);
        $xsc->writeString(1000);
        $xsc->writeFieldEnd();
        $xsc->writeFieldBegin('reversed', TType::BOOL, 3);
        $xsc->writeBool(0);
        $xsc->writeFieldEnd();
        $xsc->writeFieldBegin('count', TType::I32, 4);
        $xsc->writeI32(100);
        $xsc->writeFieldEnd();
        $xsc->writeFieldStop();
        $xsc->writeStructEnd();
        
        my $fname;
        my $ftype = 0;
        my $fid   = 0;
        my $tmp = {};
        $xsc->readStructBegin(\$fname);
        while (1) 
        {
          $xsc->readFieldBegin(\$fname, \$ftype, \$fid);
          if ($ftype == TType::STOP) {
            last;
          }
          SWITCH: for($fid)
          {
            /^1$/ && do{      if ($ftype == TType::STRING) {
              $xsc->readString(\$tmp->{start});
            } else {
              $xsc->skip($ftype);
            }
            last; };
            /^2$/ && do{      if ($ftype == TType::STRING) {
              $xsc->readString(\$tmp->{finish});
            } else {
              $xsc->skip($ftype);
            }
            last; };
            /^3$/ && do{      if ($ftype == TType::BOOL) {
              $xsc->readBool(\$tmp->{reversed});
            } else {
              $xsc->skip($ftype);
            }
            last; };
            /^4$/ && do{      if ($ftype == TType::I32) {
              $xsc->readI32(\$tmp->{count});
            } else {
              $xsc->skip($ftype);
            }
            last; };
              $xsc->skip($ftype);
          }
          $xsc->readFieldEnd();
        }
        $xsc->readStructEnd();
    },
    BP_StructBegin_pp => sub {
        $ppp->writeStructBegin('SliceRange');
        $ppp->writeFieldBegin('start', TType::STRING, 1);
        $ppp->writeString(1);
        $ppp->writeFieldEnd();
        $ppp->writeFieldBegin('finish', TType::STRING, 2);
        $ppp->writeString(1000);
        $ppp->writeFieldEnd();
        $ppp->writeFieldBegin('reversed', TType::BOOL, 3);
        $ppp->writeBool(0);
        $ppp->writeFieldEnd();
        $ppp->writeFieldBegin('count', TType::I32, 4);
        $ppp->writeI32(100);
        $ppp->writeFieldEnd();
        $ppp->writeFieldStop();
        $ppp->writeStructEnd();
        
        my $fname;
        my $ftype = 0;
        my $fid   = 0;
        my $tmp = {};
        $ppp->readStructBegin(\$fname);
        while (1) 
        {
          $ppp->readFieldBegin(\$fname, \$ftype, \$fid);
          if ($ftype == TType::STOP) {
            last;
          }
          SWITCH: for($fid)
          {
            /^1$/ && do{      if ($ftype == TType::STRING) {
              $ppp->readString(\$tmp->{start});
            } else {
              $ppp->skip($ftype);
            }
            last; };
            /^2$/ && do{      if ($ftype == TType::STRING) {
              $ppp->readString(\$tmp->{finish});
            } else {
              $ppp->skip($ftype);
            }
            last; };
            /^3$/ && do{      if ($ftype == TType::BOOL) {
              $ppp->readBool(\$tmp->{reversed});
            } else {
              $ppp->skip($ftype);
            }
            last; };
            /^4$/ && do{      if ($ftype == TType::I32) {
              $ppp->readI32(\$tmp->{count});
            } else {
              $ppp->skip($ftype);
            }
            last; };
              $ppp->skip($ftype);
          }
          $ppp->readFieldEnd();
        }
        $ppp->readStructEnd();
    },
} );

#                     Rate  BP_MapBegin_pp  CP_MapBegin_xs  BP_MapBegin_xs
# BP_MapBegin_pp   29035/s              --            -95%            -96%
# CP_MapBegin_xs  544090/s           1774%              --            -23%
# BP_MapBegin_xs  703114/s           2322%             29%              --
#
cmpthese( -5, {
    BP_MapBegin_xs => sub {
        my ($keytype, $valtype, $size);
        $xsp->writeMapBegin(TType::STRING, TType::LIST, 42);
        $xsp->readMapBegin(\$keytype, \$valtype, \$size);
    },
    CP_MapBegin_xs => sub {
        my ($keytype, $valtype, $size);
        $xsc->writeMapBegin(TType::STRING, TType::LIST, 42);
        $xsc->readMapBegin(\$keytype, \$valtype, \$size);
    },
    BP_MapBegin_pp => sub {
        my ($keytype, $valtype, $size);
        $ppp->writeMapBegin(TType::STRING, TType::LIST, 42);
        $ppp->readMapBegin(\$keytype, \$valtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                     Rate BP_ListBegin_pp CP_ListBegin_xs BP_ListBegin_xs
# BP_ListBegin_pp  39671/s              --            -93%            -95%
# CP_ListBegin_xs 561000/s           1314%              --            -30%
# BP_ListBegin_xs 797962/s           1911%             42%              --
#
cmpthese( -5, {
    BP_ListBegin_xs => sub {
        my ($elemtype, $size);
        $xsp->writeListBegin(TType::STRUCT, 12345);
        $xsp->readListBegin(\$elemtype, \$size);
    },
    CP_ListBegin_xs => sub {
        my ($elemtype, $size);
        $xsc->writeListBegin(TType::STRUCT, 12345);
        $xsc->readListBegin(\$elemtype, \$size);
    },
    BP_ListBegin_pp => sub {
        my ($elemtype, $size);
        $ppp->writeListBegin(TType::STRUCT, 12345);
        $ppp->readListBegin(\$elemtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                    Rate BP_SetBegin_pp CP_SetBegin_xs BP_SetBegin_xs
# BP_SetBegin_pp  40080/s             --           -92%           -95%
# CP_SetBegin_xs 532991/s          1230%             --           -37%
# BP_SetBegin_xs 851160/s          2024%            60%             --
#
cmpthese( -5, {
    BP_SetBegin_xs => sub {
        my ($elemtype, $size);
        $xsp->writeSetBegin(TType::I16, 12345);
        $xsp->readSetBegin(\$elemtype, \$size);
    },
    CP_SetBegin_xs => sub {
        my ($elemtype, $size);
        $xsc->writeSetBegin(TType::I16, 12345);
        $xsc->readSetBegin(\$elemtype, \$size);
    },
    BP_SetBegin_pp => sub {
        my ($elemtype, $size);
        $ppp->writeSetBegin(TType::I16, 12345);
        $ppp->readSetBegin(\$elemtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                 Rate BP_Bool_pp CP_Bool_xs BP_Bool_xs
# BP_Bool_pp   82708/s         --       -92%       -93%
# CP_Bool_xs 1088178/s      1216%         --        -2%
# BP_Bool_xs 1115950/s      1249%         3%         --
#
cmpthese( -5, {
    BP_Bool_xs => sub {
        my $value;
        $xsp->writeBool('true');
        $xsp->readBool(\$value);
    },
    CP_Bool_xs => sub {
        my $value;
        $xsc->writeBool('true');
        $xsc->readBool(\$value);
    },
    BP_Bool_pp => sub {
        my $value;
        $ppp->writeBool('true');
        $ppp->readBool(\$value);
        $ppt->resetBuffer();
    },
} );

#                 Rate BP_Byte_pp CP_Byte_xs BP_Byte_xs
# BP_Byte_pp   82562/s         --       -93%       -93%
# CP_Byte_xs 1139571/s      1280%         --        -1%
# BP_Byte_xs 1145373/s      1287%         1%         --
#
# Note: BP/CP use the same code for byte
#
cmpthese( -5, {
    BP_Byte_xs => sub {
        my $value;
        $xsp->writeByte(100);
        $xsp->readByte(\$value);
    },
    CP_Byte_xs => sub {
        my $value;
        $xsc->writeByte(100);
        $xsc->readByte(\$value);
    },
    BP_Byte_pp => sub {
        my $value;
        $ppp->writeByte(100);
        $ppp->readByte(\$value);
        $ppt->resetBuffer();
    },
} );

#                Rate BP_I16_pp CP_I16_xs BP_I16_xs
# BP_I16_pp   76698/s        --      -89%      -93%
# CP_I16_xs  690039/s      800%        --      -38%
# BP_I16_xs 1105115/s     1341%       60%        --
#
cmpthese( -5, {
    BP_I16_xs => sub {
        my $value;
        $xsp->writeI16(65534);
        $xsp->readI16(\$value);
    },
    CP_I16_xs => sub {
        my $value;
        $xsc->writeI16(65534);
        $xsc->readI16(\$value);
    },
    BP_I16_pp => sub {
        my $value;
        $ppp->writeI16(65534);
        $ppp->readI16(\$value);
        $ppt->resetBuffer();
    },
} );

#                Rate BP_I32_pp CP_I32_xs BP_I32_xs
# BP_I32_pp   81302/s        --      -87%      -92%
# CP_I32_xs  611113/s      652%        --      -42%
# BP_I32_xs 1045987/s     1187%       71%        --
#
cmpthese( -5, {
    BP_I32_xs => sub {
        my $value;
        $xsp->writeI32(1024 * 1024);
        $xsp->readI32(\$value);
    },
    CP_I32_xs => sub {
        my $value;
        $xsc->writeI32(1024 * 1024);
        $xsc->readI32(\$value);
    },
    BP_I32_pp => sub {
        my $value;
        $ppp->writeI32(1024 * 1024);
        $ppp->readI32(\$value);
        $ppt->resetBuffer();
    },
} );

#                Rate BP_I64_pp CP_I64_xs BP_I64_xs
# BP_I64_pp   37710/s        --      -90%      -97%
# CP_I64_xs  379698/s      907%        --      -66%
# BP_I64_xs 1106984/s     2835%      192%        --
#
cmpthese( -5, {
    BP_I64_xs => sub {
        my $value;
        $xsp->writeI64((1 << 37) * -1234);
        $xsp->readI64(\$value);
    },
    CP_I64_xs => sub {
        my $value;
        $xsc->writeI64((1 << 37) * -1234);
        $xsc->readI64(\$value);
    },
    BP_I64_pp => sub {
        my $value;
        $ppp->writeI64((1 << 37) * -1234);
        $ppp->readI64(\$value);
        $ppt->resetBuffer();
    },
} );

#                   Rate BP_Double_pp CP_Double_xs BP_Double_xs
# BP_Double_pp   82082/s           --         -93%         -93%
# CP_Double_xs 1109105/s        1251%           --          -0%
# BP_Double_xs 1109916/s        1252%           0%           --
#
# Note: BP/CP are identical except for byte order
#
cmpthese( -5, {
    BP_Double_xs => sub {
        my $value;
        $xsp->writeDouble(-3.14159);
        $xsp->readDouble(\$value);
    },
    CP_Double_xs => sub {
        my $value;
        $xsc->writeDouble(-3.14159);
        $xsc->readDouble(\$value);
    },
    BP_Double_pp => sub {
        my $value;
        $ppp->writeDouble(-3.14159);
        $ppp->readDouble(\$value);
        $ppt->resetBuffer();
    },
} );

#                  Rate BP_String_pp CP_String_xs BP_String_xs
# BP_String_pp  45167/s           --         -86%         -87%
# CP_String_xs 333573/s         639%           --          -1%
# BP_String_xs 336674/s         645%           1%           --
#
cmpthese( -5, {
    BP_String_xs => sub {
        my $value;
        $xsp->writeString('This is a unicode test with русский');
        $xsp->readString(\$value);
    },
    CP_String_xs => sub {
        my $value;
        $xsc->writeString('This is a unicode test with русский');
        $xsc->readString(\$value);
    },
    BP_String_pp => sub {
        my $value;
        $ppp->writeString('This is a unicode test with русский');
        $ppp->readString(\$value);
        $ppt->resetBuffer();
    },
} );

