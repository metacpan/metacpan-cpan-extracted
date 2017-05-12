package Thrift::JSONProtocol;

=head1 NAME

Thrift::JSONProtocol

=head1 DESCRIPTION

JSON protocol implementation for thrift.

This is a full-featured protocol supporting write and read.

This code was adapted from the Java implementation.

Please see the C++ class header for a detailed description of the protocol's wire format.

=cut

use strict;
use warnings;
use Thrift;
use Thrift::Protocol;
use base qw(Thrift::Protocol Class::Accessor);

use utf8;
use Encode;
use MIME::Base64;

__PACKAGE__->mk_accessors(qw(trans context_ reader_));
sub transport { shift->{trans} }

use constant {
    COMMA     => ',',
    COLON     => ':',
    LBRACE    => '{',
    RBRACE    => '}',
    LBRACKET  => '[',
    RBRACKET  => ']',
    QUOTE     => '"',
    BACKSLASH => '\\',
    ZERO      => '0',

    ESCSEQ => join('','\\','u','0','0'),
    VERSION => 1,

    JSON_CHAR_TABLE => [
      # 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
        0,  0,  0,  0,  0,  0,  0,  0,'b','t','n',  0,'f','r',  0,  0, # 0
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, # 1
        1,  1,'"',  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, # 2
    ],

    ESCAPE_CHARS => "\"\\bfnrt",
    ESCAPE_CHAR_VALS => [ '"', '\\', "\b", "\f", "\n", "\r", "\t", ],

    NAME_BOOL   => 'tf',
    NAME_BYTE   => 'i8',
    NAME_I16    => 'i16',
    NAME_I32    => 'i32',
    NAME_I64    => 'i64',
    NAME_DOUBLE => 'dbl',
    NAME_STRUCT => 'rec',
    NAME_STRING => 'str',
    NAME_MAP    => 'map',
    NAME_LIST   => 'lst',
    NAME_SET    => 'set',
};

my %_getTypeNameForTypeID = (
    TType::BOOL   => NAME_BOOL,
    TType::BYTE   => NAME_BYTE,
    TType::I16    => NAME_I16,
    TType::I32    => NAME_I32,
    TType::I64    => NAME_I64,
    TType::DOUBLE => NAME_DOUBLE,
    TType::STRING => NAME_STRING,
    TType::STRUCT => NAME_STRUCT,
    TType::MAP    => NAME_MAP,
    TType::SET    => NAME_SET,
    TType::LIST   => NAME_LIST,
);

##
## Class methods
##

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    # Stack of nested contexts that we may be in
    $self->{contextStack_} = [];

    # Current context that we are in
    $self->{context_}      = Thrift::JSONProtocol::JSONBaseContext->new( protocol => $self );

    # Reader that manages a 1-byte buffer
    $self->{reader_}       = Thrift::JSONProtocol::LookaheadReader->new( protocol => $self );

    return $self;
}

sub getTypeNameForTypeID {
    my ($typeID) = @_;

    if (my $typeName = $_getTypeNameForTypeID{$typeID}) {
        return $typeName;
    }
    die TProtocolException->new( "Unrecognized type $typeID", TProtocolException::UNKNOWN )
}

sub getTypeIDForTypeName {
    my ($name) = @_;
    my $result = TType::STOP;
    my @name = split //, $name;
    if (int(@name) > 1) {
            if ($name[0] eq 'd') { $result = TType::DOUBLE }
        elsif ($name[0] eq 'i') {
                if ($name[1] eq '8') { $result = TType::BYTE }
            elsif ($name[1] eq '1') { $result = TType::I16 }
            elsif ($name[1] eq '3') { $result = TType::I32 }
            elsif ($name[1] eq '6') { $result = TType::I64 }
        }
        elsif ($name[0] eq 'l') { $result = TType::LIST   }
        elsif ($name[0] eq 'm') { $result = TType::MAP    }
        elsif ($name[0] eq 'r') { $result = TType::STRUCT }
        elsif ($name[0] eq 's') {
                if ($name[1] eq 't') { $result = TType::STRING }
            elsif ($name[1] eq 'e') { $result = TType::SET }
        }
        elsif ($name[0] eq 't') { $result = TType::BOOL }
    }
    if ($result == TType::STOP) {
        die TProtocolException->new("Unrecognized type", TProtocolException::UNKNOWN);
    }
    return $result;
}

sub check_utf8 {
    my ($string_ref) = @_;

    return if ! utf8::is_utf8($$string_ref);
    $$string_ref = Encode::encode_utf8($$string_ref);
}

##
## Object methods
##

#
# Helper methods
#

# Push a new JSON context onto the stack.
sub pushContext {
    my ($self, $context) = @_;
    push @{ $self->{contextStack_} }, delete $self->{context_};
    $self->{context_} = $context;
}

# Pop the last JSON context off the stack
sub popContext {
    my ($self) = @_;
    my $context = pop @{ $self->{contextStack_} };
    $self->{context_} = $context;
    return $context;
}

# Read a byte that must match $expected; otherwise an excpetion is thrown.
sub readJSONSyntaxChar {
    my ($self, $expected) = @_;
    my $got = $self->{reader_}->read();
    if ($got ne $expected) {
        die TProtocolException->new("Unexpected character: $got", TProtocolException::INVALID_DATA);
    }
    return length $got;
}

# Convenience method for writing and getting the length of the string written
sub write {
    my ($self, $string) = @_;
    $self->transport->write($string);
    return length $string;
}

#
# Read/write JSON methods
#

# Write the bytes in array buf as a JSON characters, escaping as needed
sub writeJSONString {
    my ($self, $string) = @_;
    my @b = split //, $string;

    my $xfer = 0;

    $xfer += $self->context_->write();

    $xfer += $self->write(QUOTE);

    my $len = int @b;
    for (my $i = 0; $i < $len; $i++) {
        my $ord = ord($b[$i]);
        if (($ord & 0x00FF) >= 0x30) {
            if ($b[$i] eq BACKSLASH) {
                $xfer += $self->write(BACKSLASH . BACKSLASH);
            }
            else {
                $xfer += $self->write($b[$i]);
            }
        }
        else {
            my $tmp = JSON_CHAR_TABLE->[$ord];
            if ($tmp eq '1') {
                $xfer += $self->write($b[$i]);
            }
            elsif ($tmp eq '0') {
                my $hex = unpack 'H*', chr($ord);
                $xfer += $self->write(ESCSEQ . $hex);
            }
            else {
                $xfer += $self->write(BACKSLASH . $tmp);
            }
        }
    }

    $xfer += $self->write(QUOTE);

    return $xfer;
}

# Read in a JSON string, unescaping as appropriate.. Skip reading from the
# context if skipContext is true.
sub readJSONString {
    my ($self, $string, $skipContext) = @_;

    my $xfer = 0;

    $xfer += $self->context_->read() if ! $skipContext;

    $xfer += $self->readJSONSyntaxChar(QUOTE);

    $$string = '';

    while (1) {
        my $ch = $self->reader_->read();
        $xfer++;
        if ($ch eq QUOTE) {
            last;
        }
        if ($ch eq substr ESCSEQ, 0, 1) {
            $ch = $self->reader_->read();
            $xfer++;
            if ($ch eq substr ESCSEQ, 1, 1) {
                $xfer += $self->readJSONSyntaxChar(ZERO);
                $xfer += $self->readJSONSyntaxChar(ZERO);
                my $tmp = $self->transport->readAll(2);
                $ch = chr(hex($tmp));
                $xfer += 2;
            }
            else {
                my $off = index ESCAPE_CHARS, $ch;
                if ($off == -1) {
                    die TProtocolException->new("Expected control char, got '$ch'", TProtocolException::INVALID_DATA);
                }
                $ch = ESCAPE_CHAR_VALS->[$off];
            }
        }
        $$string .= $ch;
    }

    return $xfer;
}

# Write out number as a JSON value. If the context dictates so, it will be
# wrapped in quotes to output as a JSON string.

sub writeJSONInteger {
    my ($self, $num) = @_;
    my $xfer = 0;
    $xfer += $self->context_->write;
    my $str = $num . '';
    check_utf8(\$str);
    my $escapeNum = $self->context_->escapeNum();

    $xfer += $self->write(QUOTE) if $escapeNum;
    $xfer += $self->write($str);
    $xfer += $self->write(QUOTE) if $escapeNum;
    return $xfer;
}

# Return true if the given byte could be a valid part of a JSON number.
sub isJSONNumeric {
    my ($char) = @_;
    return $char =~ m{^[-+.0-9Ee]$} ? 1 : 0;
}

# Read in a sequence of characters that are all valid in JSON numbers. Does
# not do a complete regex check to validate that this is actually a number.
sub readJSONNumericChars {
    my ($self, $str) = @_;
    my $xfer = 0;
    while (1) {
        my $ch;
        eval {
            $ch = $self->reader_->peek();
        };
        if (my $ex = $@) {
            if ($ex->isa('TTransportException') && $ex->{code} == TTransportException::END_OF_FILE) {
                last;
            }
            die $ex;
        }
        if (! isJSONNumeric($ch)) {
            last;
        }
        $$str .= $self->reader_->read();
        $xfer++;
    }
    return $xfer;
}

# Read in a JSON number. If the context dictates, read in enclosing quotes.
sub readJSONInteger {
    my ($self, $int) = @_;
    my $xfer = 0;
    $xfer += $self->context_->read();
    my $escapeNum = $self->context_->escapeNum();

    my $str;
    $xfer += $self->readJSONSyntaxChar(QUOTE) if $escapeNum;
    $xfer += $self->readJSONNumericChars(\$str);
    $xfer += $self->readJSONSyntaxChar(QUOTE) if $escapeNum;

    $$int = $str * 1;
    return $xfer;
}

# Write out a double as a JSON value. If it is NaN or infinity or if the
# context dictates escaping, write out as JSON string.
sub writeJSONDouble {
    my ($self, $num) = @_;
    my $xfer = 0;
    $xfer += $self->context_->write();
    my $str = $num . '';
    check_utf8(\$str);
    my $special = $str =~ m{^-?(N|I)} ? 1 : 0;
    my $escapeNum = $special || $self->context_->escapeNum; 

    $xfer += $self->write(QUOTE) if $escapeNum;
    $xfer += $self->write($str);
    $xfer += $self->write(QUOTE) if $escapeNum;
    return $xfer;
}

# Read in a JSON double value. Throw if the value is not wrapped in quotes
# when expected or if wrapped in quotes when not expected.
sub readJSONDouble {
    my ($self, $dub) = @_;
    my $xfer = 0;
    $xfer += $self->context_->read();

    if ($self->reader_->peek() eq QUOTE) {
        my $str;
        $xfer += $self->readJSONString(\$str, 1);
        my $special = $str =~ m{^-?(N|I)} ? 1 : 0;
        if (! $self->context_->escapeNum && ! $special) {
            # Throw exception -- we should not be in a string in this case
            die TProtocolException->new(
                "Numeric data unexpectedly quoted",
                TProtocolException::INVALID_DATA,
            );
        }
        $$dub = $str;
    }
    else {
        if ($self->context_->escapeNum()) {
            # This will throw - we should have had a quote if escapeNum == true
            $xfer += $self->readJSONSyntaxChar(QUOTE);
        }
        $xfer += $self->readJSONNumericChars($dub);
    }
    return $xfer;
}

# Write out contents of byte array b as a JSON string with base-64 encoded
# data
sub writeJSONBase64 {
    my ($self, $string) = @_;
    return $self->writeJSONString( encode_base64($string, '') );
}

# Read in a JSON string containing base-64 encoded data and decode it.
sub readJSONBase64 {
    my ($self, $string) = @_;

    my $xfer = $self->readJSONString($string);
    my $tmp = decode_base64($$string);
    $$string = $tmp;
    return $xfer;
}

sub writeJSONObjectStart {
    my ($self) = @_;
    my $xfer = 0;
    $xfer += $self->context_->write();
    $xfer += $self->write(LBRACE);
    $self->pushContext(
        Thrift::JSONProtocol::JSONPairContext->new( protocol => $self )
    );
    return $xfer;
}

sub readJSONObjectStart {
    my ($self) = @_;
    my $xfer = 0;
    $xfer += $self->context_->read();
    $xfer += $self->readJSONSyntaxChar(LBRACE);
    $self->pushContext(
        Thrift::JSONProtocol::JSONPairContext->new( protocol => $self )
    );
    return $xfer;
}

sub writeJSONObjectEnd {
    my ($self) = @_;
    $self->popContext();
    return $self->write(RBRACE);
}

sub readJSONObjectEnd {
    my ($self) = @_;
    $self->popContext();
    return $self->readJSONSyntaxChar(RBRACE);
}

sub writeJSONArrayStart {
    my ($self) = @_;
    my $xfer = 0;
    $xfer += $self->context_->write();
    $xfer += $self->write(LBRACKET);
    $self->pushContext(
        Thrift::JSONProtocol::JSONListContext->new( protocol => $self )
    );
    return $xfer;
}

sub readJSONArrayStart {
    my ($self) = @_;
    my $xfer = 0;
    $xfer += $self->context_->read();
    $xfer += $self->readJSONSyntaxChar(LBRACKET);
    $self->pushContext(
        Thrift::JSONProtocol::JSONListContext->new( protocol => $self )
    );
    return $xfer;
}

sub writeJSONArrayEnd {
    my ($self) = @_;
    $self->popContext();
    return $self->write(RBRACKET);
}

sub readJSONArrayEnd {
    my ($self) = @_;
    $self->popContext();
    return $self->readJSONSyntaxChar(RBRACKET);
}

#
# Thrift::Protocol methods
#

sub writeMessageBegin {
    my ($self, $name, $type, $seqid) = @_;

    check_utf8(\$name);
    
    my $xfer = 0;
    $xfer += $self->writeJSONArrayStart();
    $xfer += $self->writeJSONInteger(VERSION);
    $xfer += $self->writeJSONString($name);
    $xfer += $self->writeJSONInteger($type);
    $xfer += $self->writeJSONInteger($seqid);
    return $xfer;
}

sub readMessageBegin {
    my ($self, $name, $type, $seqid) = @_;

    my $xfer = 0;

    $xfer += $self->readJSONArrayStart();
    my $version;
    $xfer += $self->readJSONInteger(\$version);

    if ($version != VERSION) {
        die TProtocolException->new("Message contained bad version.", TProtocolException::BAD_VERSION);
    }

    $xfer += $self->readJSONString($name);
    $xfer += $self->readJSONInteger($type);
    $xfer += $self->readJSONInteger($seqid);
    return $xfer;
}

sub writeMessageEnd {
    my ($self) = @_;
    $self->writeJSONArrayEnd();
}

sub readMessageEnd {
    my ($self) = @_;
    $self->readJSONArrayEnd();
}

sub writeStructBegin {
    my ($self) = @_;
    $self->writeJSONObjectStart();
}

sub readStructBegin {
    my ($self, $name) = @_;
    $self->readJSONObjectStart();
}

sub writeStructEnd {
    my ($self) = @_;
    $self->writeJSONObjectEnd();
}

sub readStructEnd {
    my ($self) = @_;
    $self->readJSONObjectEnd();
}

sub writeFieldBegin {
    my ($self, $fieldName, $fieldType, $fieldId) = @_;
    my $xfer = 0;
    $xfer += $self->writeJSONInteger($fieldId);
    $xfer += $self->writeJSONObjectStart();
    $xfer += $self->writeJSONString(getTypeNameForTypeID($fieldType));
    return $xfer;
}

sub readFieldBegin {
    my ($self, $name, $fieldType, $fieldId) = @_;

    my $xfer = 0;
    my $ch = $self->reader_->peek();
    if ($ch eq RBRACE) {
        $$fieldType = TType::STOP;
    }
    else {
        $xfer += $self->readJSONInteger($fieldId);
        $xfer += $self->readJSONObjectStart();
        my $type;
        $xfer += $self->readJSONString(\$type);
        $$fieldType = getTypeIDForTypeName($type);
    }
    return $xfer;
}

sub writeFieldEnd {
    my ($self) = @_;
    $self->writeJSONObjectEnd();
}

sub readFieldEnd {
    my ($self) = @_;
    $self->readJSONObjectEnd();
}

sub writeFieldStop { 0 }

sub writeMapBegin {
    my ($self, $keyType, $valType, $size) = @_;
    my $xfer = 0;
    $xfer += $self->writeJSONArrayStart();
    $xfer += $self->writeJSONString(getTypeNameForTypeID($keyType));
    $xfer += $self->writeJSONString(getTypeNameForTypeID($valType));
    $xfer += $self->writeJSONInteger($size);
    $xfer += $self->writeJSONObjectStart();
    return $xfer;
}

sub readMapBegin {
    my ($self, $keyType, $valType, $size) = @_;
    my $xfer = 0;
    $xfer += $self->readJSONArrayStart();

    $xfer += $self->readJSONString($keyType);
    $$keyType = getTypeIDForTypeName($$keyType);

    $xfer += $self->readJSONString($valType);
    $$valType = getTypeIDForTypeName($$valType);

    $xfer += $self->readJSONInteger($size);
    $xfer += $self->readJSONObjectStart();
    return $xfer;
}

sub writeMapEnd {
    my ($self) = @_;
    return $self->writeJSONObjectEnd() + $self->writeJSONArrayEnd();
}

sub readMapEnd {
    my ($self) = @_;
    return $self->readJSONObjectEnd() + $self->readJSONArrayEnd();
}

sub writeListBegin {
    my ($self, $elemType, $size) = @_;
    my $xfer = 0;
    $xfer += $self->writeJSONArrayStart();
    $xfer += $self->writeJSONString(getTypeNameForTypeID($elemType));
    $xfer += $self->writeJSONInteger($size);
    return $xfer;
}

sub readListBegin {
    my ($self, $elemType, $size) = @_;
    my $xfer = 0;

    $xfer += $self->readJSONArrayStart();

    $xfer += $self->readJSONString($elemType);
    $$elemType = getTypeIDForTypeName($$elemType);

    $xfer += $self->readJSONInteger($size);

    return $xfer;
}

sub writeListEnd {
    my ($self) = @_;
    $self->writeJSONArrayEnd();
}

sub readListEnd {
    my ($self) = @_;
    $self->readJSONArrayEnd();
}

sub writeSetBegin {
    my $self = shift;
    $self->writeListBegin(@_);
}

sub readSetBegin {
    my $self = shift;
    $self->readListBegin(@_);
}

sub writeSetEnd {
    my ($self) = @_;
    $self->writeListEnd();
}

sub readSetEnd {
    my ($self) = @_;
    $self->readListEnd();
}

sub writeBool {
    my ($self, $b) = @_;
    $self->writeJSONInteger($b ? 1 : 0);
}

sub readBool {
    my ($self, $b) = @_;
    my $xfer = $self->readJSONInteger($b);
    $$b = $$b ? 1 : 0;
    return $xfer;
}

sub writeByte {
    my ($self, $b) = @_;
    $self->writeJSONInteger(ord($b));
}

sub readByte {
    my ($self, $b) = @_;
    my $xfer = $self->readJSONInteger($b);
    $$b = chr($$b);
    return $xfer;
}

sub writeI16 {
    my ($self, $i16) = @_;
    $self->writeJSONInteger($i16);
}

sub readI16 {
    my ($self, $i16) = @_;
    $self->readJSONInteger($i16);
}

sub writeI32 {
    my ($self, $i32) = @_;
    $self->writeJSONInteger($i32);
}

sub readI32 {
    my ($self, $i32) = @_;
    $self->readJSONInteger($i32);
}

sub writeI64 {
    my ($self, $i64) = @_;
    $self->writeJSONInteger($i64);
}

sub readI64 {
    my ($self, $i64) = @_;
    $self->readJSONInteger($i64);
}

sub writeDouble {
    my ($self, $dub) = @_;
    $self->writeJSONDouble($dub);
}

sub readDouble {
    my ($self, $dub) = @_;
    $self->readJSONDouble($dub);
}

sub writeString {
    my ($self, $str) = @_;
    check_utf8(\$str);
    $self->writeJSONString($str);
}

sub readString {
    my ($self, $str) = @_;
    $self->readJSONString($str);
}

sub writeBinary {
    my ($self, $str) = @_;
    $self->writeJSONBase64($str);
}

sub readBinary {
    my ($self, $str) = @_;
    $self->readJSONBase64($str);
}
#
# Other related packages
#

{
    package Thrift::JSONProtocolFactory;

    use strict;
    use warnings;
    use base qw(TProtocolFactory);

    sub getProtocol {
        my ($self, $transport) = @_;
        return Thrift::JSONProtocol->new($transport);
    }
}

{
    # Base class for tracking JSON contexts that may require inserting/reading
    # additional JSON syntax characters
    # This base context does nothing.
    package Thrift::JSONProtocol::JSONBaseContext;

    use strict;
    use warnings;
    use base qw(Class::Accessor);
    BEGIN {
        __PACKAGE__->mk_accessors(qw(protocol));
    };

    sub new {
        my ($class, %self) = @_;
        return bless \%self, $class;
    }

    sub write { 0 }
    sub read  { 0 }
    sub escapeNum { 0 }
}

{
    # Context for JSON lists. Will insert/read commas before each item except
    # for the first one
    package Thrift::JSONProtocol::JSONListContext;

    use strict;
    use warnings;
    use base qw(Thrift::JSONProtocol::JSONBaseContext);
    BEGIN {
        __PACKAGE__->mk_accessors(qw(first_));
    };

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->first_(1);
        return $self;
    }

    sub write {
        my ($self) = @_;
        if ($self->first_) {
            $self->first_(0);
            return 0;
        }
        else {
            $self->protocol->transport->write(Thrift::JSONProtocol::COMMA);
            return length Thrift::JSONProtocol::COMMA;
        }
    }

    sub read {
        my ($self) = @_;
        if ($self->first_) {
            $self->first_(0);
            return 0;
        }
        else {
            $self->protocol->readJSONSyntaxChar(Thrift::JSONProtocol::COMMA);
            return length Thrift::JSONProtocol::COMMA;
        }
    }
}

{
    # Context for JSON records. Will insert/read colons before the value portion
    # of each record pair, and commas before each key except the first. In
    # addition, will indicate that numbers in the key position need to be
    # escaped in quotes (since JSON keys must be strings).
    package Thrift::JSONProtocol::JSONPairContext;

    use strict;
    use warnings;
    use base qw(Thrift::JSONProtocol::JSONBaseContext);
    BEGIN {
        __PACKAGE__->mk_accessors(qw(first_ colon_));
    };

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->first_(1);
        $self->colon_(1);
        return $self;
    }

    sub write {
        my ($self) = @_;

        if ($self->first_) {
            $self->first_(0);
            $self->colon_(1);
            return 0;
        }
        else {
            my $string = $self->colon_ ? Thrift::JSONProtocol::COLON : Thrift::JSONProtocol::COMMA;
            $self->protocol->transport->write($string);
            $self->colon_($self->colon_ ? 0 : 1);
            return length $string;
        }
    }

    sub read {
        my ($self) = @_;

        if ($self->first_) {
            $self->first_(0);
            $self->colon_(1);
            return 0;
        }
        else {
            my $string = $self->colon_ ? Thrift::JSONProtocol::COLON : Thrift::JSONProtocol::COMMA;
            $self->protocol->readJSONSyntaxChar($string);
            $self->colon_($self->colon_ ? 0 : 1);
            return length $string;
        }
    }

    sub escapeNum {
        my ($self) = @_;
        return $self->colon_;
    }
}

{
    # Holds up to one byte from the transport
    package Thrift::JSONProtocol::LookaheadReader;

    use strict;
    use warnings;
    use base qw(Class::Accessor);
    BEGIN {
        __PACKAGE__->mk_accessors(qw(protocol hasData_ data_));
    };

    sub new {
        my ($class, %self) = @_;
        return bless \%self, $class;
    }

    # Return and consume the next byte to be read, either taking it from the
    # data buffer if present or getting it from the transport otherwise.
    sub read {
        my ($self) = @_;
        if ($self->hasData_) {
            $self->hasData_(0);
        }
        else {
            $self->data_( $self->protocol->transport->readAll(1) );
        }
        return $self->data_;
    }

    # Return the next byte to be read without consuming, filling the data
    # buffer if it has not been filled already.
    sub peek {
        my ($self) = @_;
        if (! $self->hasData_) {
            $self->data_( $self->protocol->transport->readAll(1) );
        }
        $self->hasData_(1);
        return $self->data_;
    }
}

1;
