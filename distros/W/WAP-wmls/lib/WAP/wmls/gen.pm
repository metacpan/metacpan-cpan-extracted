use strict;
use warnings;

package WAP::wmls::multibyte;

sub size {
    my ($value) = @_;
    my $size;
    for ($size = 1; $value >= 0x80; $value >>= 7) {
        $size ++;
    }
    return $size;
}

###############################################################################

package WAP::wmls::asm;

use Encode;

use constant INTEGER_8      => 0;
use constant INTEGER_16     => 1;
use constant INTEGER_32     => 2;
use constant FLOAT_32       => 3;
use constant UTF8_STRING    => 4;
use constant EMPTY_STRING   => 5;
use constant STRING         => 6;

our ($OUT, $VERBOSE);

sub _put_mb {
    my ($value) = @_;
    my $tmp = chr($value & 0x7f);
    for ($value >>= 7; $value != 0; $value >>= 7) {
        $tmp = chr(0x80 | ($value & 0x7f)) . $tmp;
    }
    print $OUT $tmp;
    return;
}

sub _put_uint8 {
    my ($value) = @_;
    print $OUT chr $value;
    return;
}

sub _put_int8 {
    my ($value) = @_;
    print $OUT pack 'c', $value;
    return;
}

sub _put_uint16 {
    my ($value) = @_;
    print $OUT pack 'n', $value;
    return;
}

sub _put_int16 {
    my ($value) = @_;
    print $OUT pack 'n', unpack 'v', pack 's', $value;
    return;
}

sub _put_int32 {
    my ($value) = @_;
    print $OUT pack 'N', unpack 'V', pack 'l', $value;
    return;
}

sub _put_float32 {
    my ($value) = @_;
    print $OUT pack 'f', $value;
    return;
}

sub _put_string {
    my ($value) = @_;
    print $OUT $value;
    return;
}

my @mnemo = (
    '?',
    'JUMP_FW',
    'JUMP_FW_W',
    'JUMP_BW',
    'JUMP_BW_W',
    'TJUMP_FW',
    'TJUMP_FW_W',
    'TJUMP_BW',
    'TJUMP_BW_W',
    'CALL',
    'CALL_LIB',
    'CALL_LIB_W',
    'CALL_URL',
    'CALL_URL_W',
    'LOAD_VAR',
    'STORE_VAR',
    'INCR_VAR',
    'DECR_VAR',
    'LOAD_CONST',
    'LOAD_CONST_W',
    'CONST_0',
    'CONST_1',
    'CONST_M1',
    'CONST_ES',
    'CONST_INVALID',
    'CONST_TRUE',
    'CONST_FALSE',
    'INCR',
    'DECR',
    'ADD_ASG',
    'SUB_ASG',
    'UMINUS',
    'ADD',
    'SUB',
    'MUL',
    'DIV',
    'IDIV',
    'REM',
    'B_AND',
    'B_OR',
    'B_XOR',
    'B_NOT',
    'B_LSHIFT',
    'B_RSSHIFT',
    'B_RSZSHIFT',
    'EQ',
    'LE',
    'LT',
    'GE',
    'GT',
    'NE',
    'NOT',
    'SCAND',
    'SCOR',
    'TOBOOL',
    'POP',
    'TYPEOF',
    'ISVALID',
    'RETURN',
    'RETURN_ES',
    'DEBUG',
    '?',
    '?',
    '?',
    'STORE_VAR_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'LOAD_CONST_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'CALL_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'CALL_LIB_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'INCR_VAR_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'JUMP_FW_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'JUMP_BW_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'TJUMP_FW_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    'LOAD_VAR_S',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
    '?',
);

sub asmOpcode1 {
    my ($bytecode) = @_;
    print $VERBOSE sprintf("%-14s\t", $mnemo[$bytecode])
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    return;
}

sub asmOpcode1s {
    my ($bytecode, $offset) = @_;
    print $VERBOSE sprintf("%-14s%7u\t", $mnemo[$bytecode], $offset)
            if (defined $VERBOSE);
    _put_uint8(($bytecode | $offset));
    return;
}

sub asmOpcode2 {
    my ($bytecode, $offset) = @_;
    #  LOAD_CONST
    print $VERBOSE sprintf("%-14s%7u\t", $mnemo[$bytecode], $offset)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint8($offset);
    return;
}

sub asmOpcode2s {
    my ($bytecode, $idx1, $idx2) = @_;
    #  CALL_LIB_S
    print $VERBOSE sprintf("%-14s%7u%7u\t", $mnemo[$bytecode], $idx1, $idx2)
            if (defined $VERBOSE);
    _put_uint8($bytecode | $idx1);
    _put_uint8($idx2);
    return;
}

sub asmOpcode3 {
    my ($bytecode, $idx1, $idx2) = @_;
    #  CALL_LIB
    print $VERBOSE sprintf("%-14s%7u%7u\t", $mnemo[$bytecode], $idx1, $idx2)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint8($idx1);
    _put_uint8($idx2);
    return;
}

sub asmOpcode3w {
    my ($bytecode, $offset) = @_;
    #  LOAD_CONST_W, JUMP_xW_W
    print $VERBOSE sprintf("%-14s%7u\t", $mnemo[$bytecode], $offset)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint16($offset);
    return;
}

sub asmOpcode4 {
    my ($bytecode, $idx1, $idx2, $idx3) = @_;
    #  CALL_URL
    print $VERBOSE sprintf("%-14s%7u%7u%7u\t", $mnemo[$bytecode], $idx1, $idx2, $idx3)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint8($idx1);
    _put_uint8($idx2);
    _put_uint8($idx3);
    return;
}

sub asmOpcode4w {
    my ($bytecode, $idx1, $idx2) = @_;
    #  CALL_LIB_W
    print $VERBOSE sprintf("%-14s%7u%7u\t", $mnemo[$bytecode], $idx1, $idx2)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint8($idx1);
    _put_uint16($idx2);
    return;
}

sub asmOpcode6 {
    my ($bytecode, $idx1, $idx2, $idx3) = @_;
    #  CALL_URL_W
    print $VERBOSE sprintf("%-14s%7u%7u%7u\t", $mnemo[$bytecode], $idx1, $idx2, $idx3)
            if (defined $VERBOSE);
    _put_uint8($bytecode);
    _put_uint16($idx1);
    _put_uint16($idx2);
    _put_uint8($idx3);
    return;
}

sub asmByte {
    my ($str, $value) = @_;
    print $VERBOSE "$str $value\n"
            if (defined $VERBOSE);
    _put_uint8($value);
    return;
}

sub asmMultiByte {
    my ($str, $value) = @_;
    print $VERBOSE "$str $value\n"
            if (defined $VERBOSE);
    _put_mb($value);
    return;
}

sub asmFunctionName {
    my ($idx, $name) = @_;
    my $len = length $name;
    print $VERBOSE "$idx\t[$len]\t$name\n"
            if (defined $VERBOSE);
    _put_uint8($idx);
    _put_uint8($len);
    _put_string($name);
    return;
}

sub asmPragma1 {
    my ($type, $value1) = @_;
    print $VERBOSE sprintf("prag%7u%7u\n", $type, $value1)
            if (defined $VERBOSE);
    _put_uint8($type);
    _put_mb($value1);
    return;
}

sub asmPragma2 {
    my ($type, $value1, $value2) = @_;
    print $VERBOSE sprintf("prag%7u%7u%7u\n", $type, $value1, $value2)
            if (defined $VERBOSE);
    _put_uint8($type);
    _put_mb($value1);
    _put_mb($value2);
    return;
}

sub asmPragma3 {
    my ($type, $value1, $value2, $value3) = @_;
    print $VERBOSE sprintf("prag%7u%7u%7u%7u\n", $type, $value1, $value2, $value3)
            if (defined $VERBOSE);
    _put_uint8($type);
    _put_mb($value1);
    _put_mb($value2);
    _put_mb($value3);
    return;
}

sub asmConstantInteger8 {
    my ($idx, $value) = @_;
    print $VERBOSE sprintf("cst%-7u%7u%7d\n", $idx, INTEGER_8, $value)
            if (defined $VERBOSE);
    _put_uint8(INTEGER_8);
    _put_int8($value);
    return;
}

sub asmConstantInteger16 {
    my ($idx, $value) = @_;
    print $VERBOSE sprintf("cst%-7u%7u%7d\n", $idx, INTEGER_16, $value)
            if (defined $VERBOSE);
    _put_uint8(INTEGER_16);
    _put_int16($value);
    return;
}

sub asmConstantInteger32 {
    my ($idx, $value) = @_;
    print $VERBOSE sprintf("cst%-7u%7u%7d\n", $idx, INTEGER_32, $value)
            if (defined $VERBOSE);
    _put_uint8(INTEGER_32);
    _put_int32($value);
    return;
}

sub asmConstantFloat32 {
    my ($idx, $value) = @_;
    print $VERBOSE sprintf("cst%-7u%7u %f\n", $idx, FLOAT_32, $value)
            if (defined $VERBOSE);
    _put_uint8(FLOAT_32);
    _put_float32($value);
    return;
}

sub asmConstantStringUTF8 {
    my ($idx, $value) = @_;
    my $octets = encode('utf8', $value);
    my $len = length $octets;
    print $VERBOSE sprintf("cst%-7u%7u\t[%u]\t%s\n", $idx, UTF8_STRING, $len, $value)
            if (defined $VERBOSE);
    _put_uint8(UTF8_STRING);
    _put_mb($len);
    _put_string($octets);
    return;
}

sub asmConstantString {
    my ($idx, $value) = @_;
    my $len = length $value;
    print $VERBOSE sprintf("cst%-7u%7u\t[%u]\t%s\n", $idx, STRING, $len, $value)
            if (defined $VERBOSE);
    _put_uint8(STRING);
    _put_mb($len);
    _put_string($value);
    return;
}

sub asmComment {
    my ($comment) = @_;
    if (defined $comment) {
        print $VERBOSE "; $comment\n"
                if (defined $VERBOSE);
    }
    else {
        print $VERBOSE "\n"
                if (defined $VERBOSE);
    }
    return;
}

###############################################################################

package WAP::wmls::verbose;

my $_Lineno = 0;
my $IN;

sub Init {
    my ($filename) = @_;
    open $IN, '<', $filename
        or die "can't open $filename ($!).\n";
    return;
}

sub Source {
    my ($opcode) = @_;
    if (defined $WAP::wmls::asm::VERBOSE) {
        my $lineno = $opcode->{Lineno};
        while ($lineno > $_Lineno) {
            my $line = <$IN>;
            print $WAP::wmls::asm::VERBOSE sprintf(";line:%5d;\t", $_Lineno + 1);
            print $WAP::wmls::asm::VERBOSE $line if ($line);
            $_Lineno ++;
        }
    }
    return;
}

sub End {
    close $IN;
    return;
}

###############################################################################

package WAP::wmls::constantVisitor;

use Carp;

use Encode;

use constant INT8_MIN   =>   -128;
use constant INT8_MAX   =>    127;
use constant INT16_MIN  => -32768;
use constant INT16_MAX  =>  32767;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my ($parser) = @_;
    $self->{parser} = $parser;
    $self->{nb} = 0;
    $self->{size} = 0;
    $self->{action} = 0;
    $self->{cst} = {
        TYPE_INTEGER        => {},
        TYPE_FLOAT          => {},
        TYPE_STRING         => {},
        TYPE_UTF8_STRING    => {},
    };
    return $self;
}

sub visitUrl {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    if ($def->{NbUse} == 0) {
        unless ($self->{action}) {
            $self->{parser}->genWarning($opcode, "Unreferenced url - $def->{Symbol}.\n");
        }
    }
    else {
        unless ($self->{action}) {
            $def->{Index} = $self->{nb};
        }
        $opcode->{Value}->visit($self);     # LOAD_CONST
    }
    return;
}

sub visitAccessDomain {
    my $self = shift;
    my ($opcode) = @_;
    $opcode->{Value}->visit($self);         # LOAD_CONST
    return;
}

sub visitAccessPath {
    my $self = shift;
    my ($opcode) = @_;
    $opcode->{Value}->visit($self);         # LOAD_CONST
    return;
}

sub visitMetaName {}

sub visitMetaHttpEquiv {}

sub visitMetaUserAgent {
    my $self = shift;
    my ($opcode) = @_;
    $opcode->{Value}->visit($self);         # LOAD_CONST
    return;
}

sub visitFunction {
    my $self = shift;
    my ($opcode) = @_;
    $opcode->{Value}->visitActive($self)
            if (defined $opcode->{Value});
    return;
}

sub visitLoadVar {}

sub visitStoreVar {}

sub visitIncrVar {}

sub visitDecrVar {}

sub visitAddAsg {}

sub visitSubAsg {}

sub visitLabel {}

sub visitPop {}

sub visitToBool {}

sub visitScOr {}

sub visitScAnd {}

sub visitReturn {}

sub visitReturnES {}

sub visitCall {}

sub visitCallLib {}

sub visitCallUrl {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $value = $def->{FunctionName};
    unless ($self->{action}) {
        if (exists $self->{cst}->{TYPE_UTF8_STRING}{$value}) {
            $opcode->{Index} = $self->{cst}->{TYPE_UTF8_STRING}{$value};
            $opcode->{Doublon} = 1;
            return;
        }
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmConstantString($opcode->{Index}, $value)
                unless (exists $opcode->{Doublon});
    }
    else {
        $opcode->{Index} = $self->{nb};
        $self->{cst}->{TYPE_UTF8_STRING}{$value} = $self->{nb};
        $self->{size} += 1;
        $self->{size} += WAP::wmls::multibyte::size(length $value);
        $self->{size} += length $value;
        $self->{nb} += 1;
    }
    return;
}

sub visitJump {}

sub visitFalseJump {}

sub visitUnaryOp {}

sub visitBinaryOp {}

sub visitLoadConst {
    my $self = shift;
    my ($opcode) = @_;
    my $type = $opcode->{TypeDef};
    if    ($type eq 'TYPE_INTEGER') {
        $self->{parser}->checkRangeInteger($opcode);
    }
    elsif ($type eq 'TYPE_FLOAT') {
        $self->{parser}->checkRangeFloat($opcode);
    }
    $type = $opcode->{TypeDef};
    if (   $type eq 'TYPE_BOOLEAN'
        or $type eq 'TYPE_INVALID' ) {
        return;
    }
    my $value = $opcode->{Value};
    unless ($self->{action}) {
        if (exists $self->{cst}->{$type}{$value}) {
            $opcode->{Index} = $self->{cst}->{$type}{$value};
            $opcode->{Doublon} = 1;
            return;
        }
    }
    if    ($type eq 'TYPE_INTEGER') {
        return if ($value >= -1 and $value <= 1);
        if    ($value >= INT8_MIN and $value <= INT8_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmConstantInteger8($opcode->{Index}, $value)
                        unless (exists $opcode->{Doublon});
            }
            else {
                $opcode->{Index} = $self->{nb};
                $self->{cst}->{TYPE_INTEGER}{$value} = $self->{nb};
                $self->{size} += 2;
                $self->{nb} += 1;
            }
        }
        elsif ($value >= INT16_MIN and $value <= INT16_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmConstantInteger16($opcode->{Index}, $value)
                        unless (exists $opcode->{Doublon});
            }
            else {
                $opcode->{Index} = $self->{nb};
                $self->{cst}->{TYPE_INTEGER}{$value} = $self->{nb};
                $self->{size} += 3;
                $self->{nb} += 1;
            }
        }
        else {
            if ($self->{action}) {
                WAP::wmls::asm::asmConstantInteger32($opcode->{Index}, $value)
                        unless (exists $opcode->{Doublon});
            }
            else {
                $opcode->{Index} = $self->{nb};
                $self->{cst}->{TYPE_INTEGER}{$value} = $self->{nb};
                $self->{size} += 5;
                $self->{nb} += 1;
            }
        }
    }
    elsif ($type eq 'TYPE_FLOAT') {
        if ($self->{action}) {
            WAP::wmls::asm::asmConstantFloat32($opcode->{Index}, $value)
                    unless (exists $opcode->{Doublon});
        }
        else {
            $opcode->{Index} = $self->{nb};
            $self->{cst}->{TYPE_FLOAT}{$value} = $self->{nb};
            $self->{size} += 5;
            $self->{nb} += 1;
        }
    }
    elsif ($type eq 'TYPE_UTF8_STRING') {
        return unless (length $value);
        if ($self->{action}) {
            WAP::wmls::asm::asmConstantStringUTF8($opcode->{Index}, $value)
                    unless (exists $opcode->{Doublon});
        }
        else {
            my $octets = encode('utf8', $value);
            $opcode->{Index} = $self->{nb};
            $self->{cst}->{TYPE_UTF8_STRING}{$value} = $self->{nb};
            $self->{size} += 1;
            $self->{size} += WAP::wmls::multibyte::size(length $octets);
            $self->{size} += length $octets;
            $self->{nb} += 1;
        }
    }
    elsif ($type eq 'TYPE_STRING') {
        return unless (length $value);
        if ($self->{action}) {
            WAP::wmls::asm::asmConstantString($opcode->{Index}, $value)
                    unless (exists $opcode->{Doublon});
        }
        else {
            $opcode->{Index} = $self->{nb};
            $self->{cst}->{TYPE_STRING}{$value} = $self->{nb};
            $self->{size} += 1;
            $self->{size} += WAP::wmls::multibyte::size(length $value);
            $self->{size} += length $value;
            $self->{nb} += 1;
        }
    }
    else {
        croak "INTERNAL ERROR in constantVisitor::visitLoadConst $type $value\n";
    }
    return;
}

###############################################################################

package WAP::wmls::pragmaVisitor;

use constant ACCESS_DOMAIN                      => 0;
use constant ACCESS_PATH                        => 1;
use constant USER_AGENT_PROPERTY                => 2;
use constant USER_AGENT_PROPERTY_AND_SCHEME     => 3;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my ($parser) = @_;
    $self->{parser} = $parser;
    $self->{nb} = 0;
    $self->{size} = 0;
    $self->{action} = 0;
    return $self;
}

sub visitUrl {}

sub visitAccessDomain {
    my $self = shift;
    my ($opcode) = @_;
    my $pragma = $opcode->{Value};
    my $value = $pragma->{OpCode}->{Index};
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmPragma1(ACCESS_DOMAIN, $value);
    }
    else {
        $self->{size} += 1;
        $self->{size} += WAP::wmls::multibyte::size($value);
        $self->{nb} += 1;
    }
    return;
}

sub visitAccessPath {
    my $self = shift;
    my ($opcode) = @_;
    my $pragma = $opcode->{Value};
    my $value = $pragma->{OpCode}->{Index};
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmPragma1(ACCESS_PATH, $value);
    }
    else {
        $self->{size} += 1;
        $self->{size} += WAP::wmls::multibyte::size($value);
        $self->{nb} += 1;
    }
    return;
}

sub visitMetaName {}

sub visitMetaHttpEquiv {}

sub visitMetaUserAgent {
    my $self = shift;
    my ($opcode) = @_;
    my $pragma1 = $opcode->{Value};
    my $value1 = $pragma1->{OpCode}->{Index};
    my $pragma2 = $pragma1->{Next};
    my $value2 = $pragma2->{OpCode}->{Index};
    my $pragma3 = $pragma2->{Next};
    if (defined $pragma3) {
        my $value3 = $pragma3->{OpCode}->{Index};
        if ($self->{action}) {
            WAP::wmls::verbose::Source($opcode);
            WAP::wmls::asm::asmPragma3(USER_AGENT_PROPERTY_AND_SCHEME, $value1, $value2, $value3);
        }
        else {
            $self->{size} += 1;
            $self->{size} += WAP::wmls::multibyte::size($value1);
            $self->{size} += WAP::wmls::multibyte::size($value2);
            $self->{size} += WAP::wmls::multibyte::size($value3);
            $self->{nb} += 1;
        }
    }
    else {
        if ($self->{action}) {
            WAP::wmls::verbose::Source($opcode);
            WAP::wmls::asm::asmPragma2(USER_AGENT_PROPERTY, $value1, $value2);
        }
        else {
            $self->{size} += 1;
            $self->{size} += WAP::wmls::multibyte::size($value1);
            $self->{size} += WAP::wmls::multibyte::size($value2);
            $self->{nb} += 1;
        }
    }
    return;
}

###############################################################################

package WAP::wmls::codeVisitor;

use Carp;

use constant JUMP_FW_S      => 0x80;
use constant JUMP_FW        => 0x01;
use constant JUMP_FW_W      => 0x02;
use constant JUMP_BW_S      => 0xA0;
use constant JUMP_BW        => 0x03;
use constant JUMP_BW_W      => 0x04;
use constant TJUMP_FW_S     => 0xC0;
use constant TJUMP_FW       => 0x05;
use constant TJUMP_FW_W     => 0x06;
use constant TJUMP_BW       => 0x07;
use constant TJUMP_BW_W     => 0x08;
use constant CALL_S         => 0x60;
use constant CALL           => 0x09;
use constant CALL_LIB_S     => 0x68;
use constant CALL_LIB       => 0x0A;
use constant CALL_LIB_W     => 0x0B;
use constant CALL_URL       => 0x0C;
use constant CALL_URL_W     => 0x0D;
use constant LOAD_VAR_S     => 0xE0;
use constant LOAD_VAR       => 0x0E;
use constant STORE_VAR_S    => 0x40;
use constant STORE_VAR      => 0x0F;
use constant INCR_VAR_S     => 0x70;
use constant INCR_VAR       => 0x10;
use constant DECR_VAR       => 0x11;
use constant LOAD_CONST_S   => 0x50;
use constant LOAD_CONST     => 0x12;
use constant LOAD_CONST_W   => 0x13;
use constant CONST_0        => 0x14;
use constant CONST_1        => 0x15;
use constant CONST_M1       => 0x16;
use constant CONST_ES       => 0x17;
use constant CONST_INVALID  => 0x18;
use constant CONST_TRUE     => 0x19;
use constant CONST_FALSE    => 0x1A;
use constant INCR           => 0x1B;
use constant DECR           => 0x1C;
use constant ADD_ASG        => 0x1D;
use constant SUB_ASG        => 0x1E;
use constant UMINUS         => 0x1F;
use constant ADD            => 0x20;
use constant SUB            => 0x21;
use constant MUL            => 0x22;
use constant DIV            => 0x23;
use constant IDIV           => 0x24;
use constant REM            => 0x25;
use constant B_AND          => 0x26;
use constant B_OR           => 0x27;
use constant B_XOR          => 0x28;
use constant B_NOT          => 0x29;
use constant B_LSHIFT       => 0x2A;
use constant B_RSSHIFT      => 0x2B;
use constant B_RSZSHIFT     => 0x2C;
use constant _EQ            => 0x2D;
use constant _LE            => 0x2E;
use constant _LT            => 0x2F;
use constant _GE            => 0x30;
use constant _GT            => 0x31;
use constant _NE            => 0x32;
use constant NOT            => 0x33;
use constant SCAND          => 0x34;
use constant SCOR           => 0x35;
use constant TOBOOL         => 0x36;
use constant POP            => 0x37;
use constant TYPEOF         => 0x38;
use constant ISVALID        => 0x39;
use constant RETURN         => 0x3A;
use constant RETURN_ES      => 0x3B;
use constant DEBUG          => 0x3C;

use constant UINT3_MAX      => 7;
use constant UINT4_MAX      => 15;
use constant UINT5_MAX      => 31;
use constant UINT8_MAX      => 255;
use constant UINT16_MAX     => 65535;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my ($parser) = @_;
    $self->{parser} = $parser;
    $self->{nb} = 0;
    $self->{size} = 0;
    $self->{action} = 0;
    return $self;
}

sub visitFunction {
    my $self = shift;
    my ($opcode) = @_;
    my $func = $opcode->{Value};
    my $def = $opcode->{Definition};
    my $save_size = $self->{size};
    $self->{size} = 0;
    if ($self->{action}) {
        my $FunctionSize = $opcode->{Index};
        WAP::wmls::asm::asmComment("function prologue");
        WAP::wmls::asm::asmByte("NumberOfArguments", $def->{NumberOfArguments});
        WAP::wmls::asm::asmByte("NumberOfLocalVariables", $def->{NumberOfLocalVariables});
        WAP::wmls::asm::asmMultiByte("FunctionSize", $FunctionSize);
        WAP::wmls::asm::asmComment("function code");
        $func->visitActive($self)
                if (defined $func);
        WAP::wmls::verbose::Source($opcode);
    }
    else {
        my $nb = $self->_indexeVariables($func, $def->{NumberOfArguments});
        if ($nb > UINT8_MAX) {
            $self->{parser}->genError($opcode, "too many variables");
        }
        else {
            $def->{NumberOfLocalVariables} = $nb - $def->{NumberOfArguments};
            my $func_size;
            do {
                $func_size = $self->{size};
                $self->{size} = 0;
                $func->visitActive($self)
                        if (defined $func);
#               print "size : $self->{size}\n";
            }
            while (     $func_size != $self->{size}
                    and !exists $self->{parser}->YYData->{nb_error} );
        }
        $opcode->{Index} = $self->{size};
    }
    $self->{size} = $save_size;
    $self->{size} += 2;
    $self->{size} += WAP::wmls::multibyte::size($opcode->{Index});
    $self->{size} += $opcode->{Index};
    return;
}

sub _indexeVariables {
    my $self = shift;
    my ($func, $nb_args) = @_;
    my $idx = $nb_args;
    if (defined $func) {
        for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
            my $opcode = $node->{OpCode};
            if ( $opcode->isa('LoadVar')
              or $opcode->isa('StoreVar')
              or $opcode->isa('IncrVar')
              or $opcode->isa('DecrVar')
              or $opcode->isa('AddAsg')
              or $opcode->isa('SubAsg') ) {
                my $def = $opcode->{Definition};
                if ($def->{ID} == 0xffff) {
                    $def->{ID} = $idx;
                    $idx ++;
                }
            }
        }
    }
    return $idx;
}

sub visitLoadVar {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitDecrVar\n"
            unless ($vindex <= UINT8_MAX);
    if ($vindex <= UINT5_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode1s(LOAD_VAR_S, $vindex);
        }
        $self->{size} += 1;
    }
    else {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode2(LOAD_VAR, $vindex);
        }
        $self->{size} += 2;
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitStoreVar {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitDecrVar\n"
            unless ($vindex <= UINT8_MAX);
    if ($vindex <= UINT4_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode1s(STORE_VAR_S, $vindex);
        }
        $self->{size} += 1;
    }
    else {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode2(STORE_VAR, $vindex);
        }
        $self->{size} += 2;
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitIncrVar {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitDecrVar\n"
            unless ($vindex <= UINT8_MAX);
    if ($vindex <= UINT3_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode1s(INCR_VAR_S, $vindex);
        }
        $self->{size} += 1;
    }
    else {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode2(INCR_VAR, $vindex);
        }
        $self->{size} += 2;
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitDecrVar {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitDecrVar\n"
            unless ($vindex <= UINT8_MAX);
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode2(DECR_VAR, $vindex);
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    $self->{size} += 2;
    return;
}

sub visitAddAsg {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitAddAsg\n"
            unless ($vindex <= UINT8_MAX);
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode2(ADD_ASG, $vindex);
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    $self->{size} += 2;
    return;
}

sub visitSubAsg {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $vindex = $def->{ID};
    croak "INTERNAL ERROR in codeVisitor::visitSubAsg\n"
            unless ($vindex <= UINT8_MAX);
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode2(SUB_ASG, $vindex);
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    $self->{size} += 2;
    return;
}

sub visitLabel {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        # no verbose
        WAP::wmls::asm::asmComment($opcode->{Definition}->{Symbol});
    }
    $opcode->{Definition}->{Index} = $self->{size};
    return;
}

sub visitPop {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        # no verbose
        WAP::wmls::asm::asmOpcode1(POP);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitToBool {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode1(TOBOOL);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitScOr {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode1(SCOR);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitScAnd {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode1(SCAND);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitReturn {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode1(RETURN);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitReturnES {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        WAP::wmls::asm::asmOpcode1(RETURN_ES);
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitCall {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $def = $opcode->{Definition};
    my $symb = $def->{Symbol};
    if ($def->{Type} ne 'UNDEF_FUNC') {
        my $nb_args = $def->{NumberOfArguments};
        my $findex = $def->{ID};
        croak "INTERNAL ERROR in codeVisitor::visitCallLib\n"
                unless ($nb_args <= UINT8_MAX);
        croak "INTERNAL ERROR in codeVisitor::visitCall\n"
                unless ($findex <= UINT8_MAX);
        if ($nb_args != $opcode->{Index}) {
            $self->{parser}->genError($opcode, "Wrong argument number for local function - $symb.\n");
        }
        elsif ($findex <= UINT3_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1s(CALL_S, $findex);
            }
            $self->{size} += 1;
        }
        else {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(CALL, $findex);
            }
            $self->{size} += 2;
        }
        if ($self->{action}) {
            WAP::wmls::asm::asmComment($def->{Symbol});
        }
    }
    else {
        $self->{parser}->genError($opcode, "Undefined function - $symb.\n");
    }
    return;
}

sub visitCallLib {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $def = $opcode->{Definition};
    my $findex = $def->{ID};
    my $lindex = $def->{LibraryID};
    croak "INTERNAL ERROR in codeVisitor::visitCallLib\n"
            unless ($findex <= UINT8_MAX);
    if ($findex <= UINT3_MAX and $lindex <= UINT8_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode2s(CALL_LIB_S, $findex, $lindex);
        }
        $self->{size} += 2;
    }
    elsif ($lindex <= UINT8_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode3(CALL_LIB, $findex, $lindex);
        }
        $self->{size} += 3;
    }
    else {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode4w(CALL_LIB_W, $findex, $lindex);
        }
        $self->{size} += 4;
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitCallUrl {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $urlindex = $opcode->{Url}->{Index};
    my $findex = $opcode->{Index};
    my $def = $opcode->{Definition};
    my $nb_args = $def->{NumberOfArguments};
    croak "INTERNAL ERROR in codeVisitor::visitCallUrl\n"
            unless ($urlindex <= UINT16_MAX and $findex <= UINT16_MAX);
    croak "INTERNAL ERROR in codeVisitor::visitCallUrl\n"
            unless ($nb_args <= UINT8_MAX);
    if ($urlindex <= UINT8_MAX and $findex <= UINT8_MAX) {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode4(CALL_URL, $urlindex, $findex, $nb_args);
        }
        $self->{size} += 4;
    }
    else {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode6(CALL_URL_W, $urlindex, $findex, $nb_args);
        }
        $self->{size} += 6;
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitJump {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $dest = $def->{Index};
    # no verbose
    if ($dest > $self->{size}) {
        my $offset = $dest - $self->{size};
        if    ($offset <= UINT5_MAX + 1) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1s(JUMP_FW_S, $offset - 1);
            }
            $self->{size} += 1;
        }
        elsif ($offset <= UINT8_MAX + 2) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(JUMP_FW, $offset - 2);
            }
            $self->{size} += 2;
        }
        elsif ($offset <= UINT16_MAX + 3) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode3w(JUMP_FW_W, $offset - 3);
            }
            $self->{size} += 3;
        }
        else {
            if ($self->{action}) {
                $self->{parser}->genError($opcode, "Too long JUMP_FW");
            }
            $self->{size} += 3;
        }
    }
    else {
        my $offset = $self->{size} - $dest;
        if    ($offset <= UINT5_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1s(JUMP_BW_S, $offset);
            }
            $self->{size} += 1;
        }
        elsif ($offset <= UINT8_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(JUMP_BW, $offset);
            }
            $self->{size} += 2;
        }
        elsif ($offset <= UINT16_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode3w(JUMP_BW_W, $offset);
            }
            $self->{size} += 3;
        }
        else {
            if ($self->{action}) {
                $self->{parser}->genError($opcode, "Too long JUMP_BW");
            }
            $self->{size} += 3;
        }
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitFalseJump {
    my $self = shift;
    my ($opcode) = @_;
    my $def = $opcode->{Definition};
    my $dest = $def->{Index};
    # no verbose
    if ($dest > $self->{size}) {
        my $offset = $dest - $self->{size};
        if    ($offset <= UINT5_MAX + 1) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1s(TJUMP_FW_S, $offset - 1);
            }
            $self->{size} += 1;
        }
        elsif ($offset <= UINT8_MAX + 2) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(TJUMP_FW, $offset - 2);
            }
            $self->{size} += 2;
        }
        elsif ($offset <= UINT16_MAX + 3) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode3w(TJUMP_FW_W, $offset - 3);
            }
            $self->{size} += 3;
        }
        else {
            if ($self->{action}) {
                $self->{parser}->genError($opcode, "Too long TJUMP_FW");
            }
            $self->{size} += 3;
        }
    }
    else {
        my $offset = $self->{size} - $dest;
        if      ($offset <= UINT8_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(TJUMP_BW, $offset);
            }
            $self->{size} += 2;
        }
        elsif ($offset <= UINT16_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode3w(TJUMP_BW_W, $offset);
            }
            $self->{size} += 3;
        }
        else {
            if ($self->{action}) {
                $self->{parser}->genError($opcode, "Too long TJUMP_BW");
            }
            $self->{size} += 3;
        }
    }
    if ($self->{action}) {
        WAP::wmls::asm::asmComment($def->{Symbol});
    }
    return;
}

sub visitUnaryOp {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        my $oper = $opcode->{Operator};
        if    ($oper eq 'typeof') {
            WAP::wmls::asm::asmOpcode1(TYPEOF);
        }
        elsif ($oper eq 'isvalid') {
            WAP::wmls::asm::asmOpcode1(ISVALID);
        }
        elsif ($oper eq '-') {
            WAP::wmls::asm::asmOpcode1(UMINUS);
        }
        elsif ($oper eq '~') {
            WAP::wmls::asm::asmOpcode1(B_NOT);
        }
        elsif ($oper eq '!') {
            WAP::wmls::asm::asmOpcode1(NOT);
        }
        elsif ($oper eq '++') {
            WAP::wmls::asm::asmOpcode1(INCR);
        }
        elsif ($oper eq '--') {
            WAP::wmls::asm::asmOpcode1(DECR);
        }
        else {
            croak "INTERNAL ERROR in codeVisitor::visitUnaryOp (oper:$oper)\n";
        }
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitBinaryOp {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
        my $oper = $opcode->{Operator};
        if    ($oper eq '+') {
            WAP::wmls::asm::asmOpcode1(ADD);
        }
        elsif ($oper eq '-') {
            WAP::wmls::asm::asmOpcode1(SUB);
        }
        elsif ($oper eq '*') {
            WAP::wmls::asm::asmOpcode1(MUL);
        }
        elsif ($oper eq '/') {
            WAP::wmls::asm::asmOpcode1(DIV);
        }
        elsif ($oper eq 'div') {
            WAP::wmls::asm::asmOpcode1(IDIV);
        }
        elsif ($oper eq '%') {
            WAP::wmls::asm::asmOpcode1(REM);
        }
        elsif ($oper eq '<<') {
            WAP::wmls::asm::asmOpcode1(B_LSHIFT);
        }
        elsif ($oper eq '>>') {
            WAP::wmls::asm::asmOpcode1(B_RSSHIFT);
        }
        elsif ($oper eq '>>>') {
            WAP::wmls::asm::asmOpcode1(B_RSZSHIFT);
        }
        elsif ($oper eq '<') {
            WAP::wmls::asm::asmOpcode1(_LT);
        }
        elsif ($oper eq '>') {
            WAP::wmls::asm::asmOpcode1(_GT);
        }
        elsif ($oper eq '<=') {
            WAP::wmls::asm::asmOpcode1(_LE);
        }
        elsif ($oper eq '>=') {
            WAP::wmls::asm::asmOpcode1(_GE);
        }
        elsif ($oper eq '==') {
            WAP::wmls::asm::asmOpcode1(_EQ);
        }
        elsif ($oper eq '!=') {
            WAP::wmls::asm::asmOpcode1(_NE);
        }
        elsif ($oper eq '&') {
            WAP::wmls::asm::asmOpcode1(B_AND);
        }
        elsif ($oper eq '^') {
            WAP::wmls::asm::asmOpcode1(B_XOR);
        }
        elsif ($oper eq '|') {
            WAP::wmls::asm::asmOpcode1(B_OR);
        }
        else {
            croak "INTERNAL ERROR in codeVisitor::visitBinaryOp (oper:$oper)\n";
        }
        WAP::wmls::asm::asmComment();
    }
    $self->{size} += 1;
    return;
}

sub visitLoadConst {
    my $self = shift;
    my ($opcode) = @_;
    if ($self->{action}) {
        WAP::wmls::verbose::Source($opcode);
    }
    my $type = $opcode->{TypeDef};
    my $value = $opcode->{Value};
#   print "index $opcode->{Index} cst $value\n";
    if    ($type eq 'TYPE_INVALID') {
        if ($self->{action}) {
            WAP::wmls::asm::asmOpcode1(CONST_INVALID);
            WAP::wmls::asm::asmComment();
        }
        $self->{size} += 1;
    }
    elsif ($type eq 'TYPE_BOOLEAN') {
        if ($self->{action}) {
            if ($value) {
                WAP::wmls::asm::asmOpcode1(CONST_TRUE);
                WAP::wmls::asm::asmComment();
            }
            else {
                WAP::wmls::asm::asmOpcode1(CONST_FALSE);
                WAP::wmls::asm::asmComment();
            }
        }
        $self->{size} += 1;
    }
    elsif ($type eq 'TYPE_STRING' or $type eq 'TYPE_UTF8_STRING') {
        if (length $value == 0) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1(CONST_ES);
                WAP::wmls::asm::asmComment();
            }
            $self->{size} += 1;
        }
        else {
            goto load_const;
        }
    }
    elsif ($type eq 'TYPE_FLOAT') {
load_const:
        my $cindex = $opcode->{Index};
        croak "INTERNAL ERROR in codeVisitor::visitLoadConst\n"
                unless ($cindex <= UINT16_MAX);
        if    ($cindex <= UINT4_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1s(LOAD_CONST_S, $cindex);
            }
            $self->{size} += 1;
        }
        elsif ($cindex <= UINT8_MAX) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode2(LOAD_CONST, $cindex);
            }
            $self->{size} += 2;
        }
        else {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode3w(LOAD_CONST_W, $cindex);
            }
            $self->{size} += 3;
        }
        if ($self->{action}) {
            WAP::wmls::asm::asmComment($value);
        }
    }
    elsif ($type eq 'TYPE_INTEGER') {
        if    ($value == 0) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1(CONST_0);
                WAP::wmls::asm::asmComment();
            }
            $self->{size} += 1;
        }
        elsif ($value == 1) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1(CONST_1);
                WAP::wmls::asm::asmComment();
            }
            $self->{size} += 1;
        }
        elsif ($value == -1) {
            if ($self->{action}) {
                WAP::wmls::asm::asmOpcode1(CONST_M1);
                WAP::wmls::asm::asmComment();
            }
            $self->{size} += 1;
        }
        else {
            goto load_const;
        }
    }
    else {
        croak "INTERNAL ERROR in codeVisitor::visitLoadConst (type:$type)\n";
    }
    return;
}

###############################################################################

package WAP::wmls::parser;

use constant WMLS_MAJOR_VERSION     => 1;
use constant WMLS_MINOR_VERSION     => 1;

sub genError {
    my $parser = shift;
    my ($opcode, $msg) = @_;

    if (exists $parser->YYData->{nb_error}) {
        $parser->YYData->{nb_error} ++;
    }
    else {
        $parser->YYData->{nb_error} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$opcode->{Lineno},'#Error: ',$msg
            if (        exists $parser->YYData->{verbose_error}
                    and $parser->YYData->{verbose_error});
    return;
}

sub genWarning {
    my $parser = shift;
    my ($opcode, $msg) = @_;

    if (exists $parser->YYData->{nb_warning}) {
        $parser->YYData->{nb_warning} ++;
    }
    else {
        $parser->YYData->{nb_warning} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$opcode->{Lineno},'#Warning: ',$msg
            if (        exists $parser->YYData->{verbose_warning}
                    and $parser->YYData->{verbose_warning});
    return;
}

sub generate {
    my $parser = shift;

    my $CharacterSet = 4;   # iso-8859-1
    # ConstantPool
    my $CodeSize = 0;
    my $constantVisitor = new WAP::wmls::constantVisitor($parser);
    $parser->YYData->{PragmaList}->visit($constantVisitor)
            if (defined $parser->YYData->{PragmaList});
    $parser->YYData->{FunctionList}->visitActive($constantVisitor)
            if (defined $parser->YYData->{FunctionList});
    my $NumberOfConstants = $constantVisitor->{nb};
    $parser->genError($parser->YYData->{FunctionList}, "Too many constants ($NumberOfConstants)")
            if ($NumberOfConstants > 65535);
    $CodeSize += WAP::wmls::multibyte::size($NumberOfConstants);
    $CodeSize += WAP::wmls::multibyte::size($CharacterSet);
    $CodeSize += $constantVisitor->{size};
    # PragmaPool
    my $pragmaVisitor = new WAP::wmls::pragmaVisitor($parser);
    $parser->YYData->{PragmaList}->visit($pragmaVisitor)
            if (defined $parser->YYData->{PragmaList});
    my $NumberOfPragmas = $pragmaVisitor->{nb};
    $parser->genError($parser->YYData->{PragmaList}, "Too many pragmas ($NumberOfPragmas)")
            if ($NumberOfPragmas > 65535);
    $CodeSize += WAP::wmls::multibyte::size($NumberOfPragmas);
    $CodeSize += $pragmaVisitor->{size};
    # FunctionPool
    my $NumberOfFunctions = 0;
    for (my $func = $parser->YYData->{FunctionList}; defined $func; $func = $func->{Next}) {
        $NumberOfFunctions ++;
    }
    $parser->genError($parser->YYData->{FunctionList}, "Too many functions ($NumberOfFunctions).\n")
            if ($NumberOfFunctions > 255);
    $CodeSize += 1;         # NumberOfFunctions
    my $NumberOfFunctionNames = 0;
    for (my $func = $parser->YYData->{FunctionList}; defined $func; $func = $func->{Next}) {
        my $def = $func->{OpCode}->{Definition};
        next if ($def->{Type} ne 'PUBLIC_FUNC');
        $NumberOfFunctionNames ++;
        $CodeSize += 1;     # idx
        $CodeSize += 1;     # length
        $CodeSize += length $def->{Symbol};
    }
    $parser->genError($parser->YYData->{FunctionList}->{OpCode}, "No external function defined.\n")
            unless ($NumberOfFunctionNames);
    $CodeSize += 1;         # NumberOfFunctionNames
    my $codeVisitor = new WAP::wmls::codeVisitor($parser);
    $parser->YYData->{FunctionList}->visitActive($codeVisitor)
            if (defined $parser->YYData->{FunctionList});
    $CodeSize += $codeVisitor->{size};

    unless (exists $parser->YYData->{nb_error}) {
        my $filename = $parser->YYData->{filename};
        $filename =~ s/\.wmls$//;
        $filename .= '.wmlsc';
        open $WAP::wmls::asm::OUT, '>', $filename
                or die "can't open $filename ($!)\n";
        binmode $WAP::wmls::asm::OUT, ':raw';

        WAP::wmls::asm::asmComment($filename);
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmComment("Bytecode Header");
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmByte("VersionNumber", 16 * (WMLS_MAJOR_VERSION - 1) + WMLS_MINOR_VERSION);
        WAP::wmls::asm::asmMultiByte("CodeSize", $CodeSize);
        WAP::wmls::asm::asmComment("Constant Pool");
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmMultiByte("NumberOfConstants", $NumberOfConstants);
        WAP::wmls::asm::asmMultiByte("CharacterSet", $CharacterSet);
        $constantVisitor->{action} = 1;
        $parser->YYData->{PragmaList}->visit($constantVisitor)
                if (defined $parser->YYData->{PragmaList});
        $parser->YYData->{FunctionList}->visitActive($constantVisitor)
                if (defined $parser->YYData->{FunctionList});
        WAP::wmls::asm::asmComment("Pragma Pool");
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmMultiByte("NumberOfPragmas", $NumberOfPragmas);
        $pragmaVisitor->{nb} = 0;
        $pragmaVisitor->{action} = 1;
        $parser->YYData->{PragmaList}->visit($pragmaVisitor)
                if (defined $parser->YYData->{PragmaList});
        WAP::wmls::asm::asmComment("Function Pool");
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmByte("NumberOfFunctions", $NumberOfFunctions);
        WAP::wmls::asm::asmComment("Function Name Table");
        WAP::wmls::asm::asmComment("");
        WAP::wmls::asm::asmByte("NumberOfFunctionNames", $NumberOfFunctionNames);
        for (my $func = $parser->YYData->{FunctionList}; defined $func; $func = $func->{Next}) {
            my $def = $func->{OpCode}->{Definition};
            next if ($def->{Type} ne 'PUBLIC_FUNC');
            WAP::wmls::asm::asmFunctionName($def->{ID}, $def->{Symbol});
        }
        WAP::wmls::asm::asmComment("Functions");
        WAP::wmls::asm::asmComment("");
        $codeVisitor->{action} = 1;
        $parser->YYData->{FunctionList}->visitActive($codeVisitor)
                if (defined $parser->YYData->{FunctionList});

        close $WAP::wmls::asm::OUT;
        unlink($filename) if (exists $parser->YYData->{nb_error});
    }
    return;
}

1;

