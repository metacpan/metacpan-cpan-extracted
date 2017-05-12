package Tripletail::Serializer;
use strict;
use warnings;
use B ();
use Compress::Zlib qw(
        Z_BEST_COMPRESSION
        Z_OK
        Z_STREAM_END
        adler32
        deflateInit
        inflateInit
      );
use Crypt::CBC ();
use Crypt::Rijndael ();
use Data::Dumper ();
use Encode qw(decode_utf8 encode_utf8);
use POSIX qw(ceil);
use Scalar::Util qw(blessed);
use constant {
        IS_ENCRYPTED  => 0x04,
        IS_COMPRESSED => 0x02,
        HAS_CHECKSUM  => 0x01
    };

BEGIN {
    use Sub::Install ();

    my $float_1_in_ieee_754 = pack('f', 1.0);
    if ($float_1_in_ieee_754 eq "\x00\x00\x80\x3F") {
        # little-endian
        my $swap = sub { return reverse shift };
        Sub::Install::install_sub({code => $swap, as => '_hton'});
        Sub::Install::install_sub({code => $swap, as => '_ntoh'});
    }
    elsif ($float_1_in_ieee_754 eq "\x3F\x80\x00\x00") {
        # big-endian
        my $id = sub { return shift };
        Sub::Install::install_sub({code => $id, as => '_hton'});
        Sub::Install::install_sub({code => $id, as => '_ntoh'});
    }
    else {
        die "failed to detect the endianness";
    }
}

sub _encodeVInt {
    my $int = shift;

    if ($int < 0) {
        die "out of range: $int";
    }
    elsif ($int <= 0x0000007F) {
        # 1xxx xxxx
        return pack('C', 0x80 | $int);
    }
    elsif ($int <= 0x00003FFF) {
        # 01xx xxxx xxxx xxxx
        return pack('n', 0x4000 | $int);
    }
    elsif ($int <= 0x001FFFFF) {
        # 001x xxxx xxxx xxxx xxxx xxxx
        return pack('Cn', 0x20 | ($int >> 16), $int);
    }
    elsif ($int <= 0x0FFFFFFF) {
        # 0001 xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        return pack('N', 0x10000000 | $int);
    }
    else {
        my $hi = $int >> 32;
        my $lo = $int & 0xFFFFFFFF;

        if    ($hi <= 0x00000007) {
            # 0000 1xxx xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx
            return pack('CN', 0x08 | $hi, $lo);
        }
        elsif ($hi <= 0x000003FF) {
            # 0000 01xx xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx xxxx xxxx
            return pack('nN', 0x0400 | $hi, $lo);
        }
        elsif ($hi <= 0x0001FFFF) {
            # 0000 001x xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx xxxx xxxx xxxx xxxx
            return pack('CnN', 0x02 | ($hi >> 16), $hi, $lo);
        }
        elsif ($hi <= 0x00FFFFFF) {
            # 0000 0001 xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
            return pack('NN', 0x01000000 | $hi, $lo);
        }
        elsif ($hi <= 0x7FFFFFFF) {
            # 0000 0000 1xxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx
            return pack('CNN', 0x00, 0x80000000 | $hi, $lo);
        }
        else {
            die "too big for this encoder to handle: $int";
        }
    }
}

sub _decodeVInt {
    my $src = shift;
    my $msg = __PACKAGE__."#deserialize: premature end of value.\n";

    die $msg if !length $src;
    my $head = unpack('C', substr($src, 0, 1));

    if ($head & 0x80) {
        # 1xxx xxxx
        return ($head & 0x7F, substr($src, 1));
    }
    elsif ($head & 0x40) {
        # 01xx xxxx xxxx xxxx
        die $msg if length($src) < 2;
        return (unpack('n', substr($src, 0, 2)) & 0x3FFF, substr($src, 2));
    }
    elsif ($head & 0x20) {
        # 001x xxxx xxxx xxxx xxxx xxxx
        die $msg if length($src) < 3;
        my $lo = unpack('n', substr($src, 1, 2));
        return ((($head & 0x1F) << 16) | $lo, substr($src, 3));
    }
    elsif ($head & 0x10) {
        # 0001 xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        die $msg if length($src) < 4;
        return (unpack('N', substr($src, 0, 4)) & 0x0FFFFFFF, substr($src, 4));
    }
    elsif ($head & 0x08) {
        # 0000 1xxx xxxx xxxx xxxx xxxx xxxx xxxx
        # xxxx xxxx
        die $msg if length($src) < 5;
        my $hi = $head & 0x07;
        my $lo = unpack('N', substr($src, 1, 4));
        return (($hi << 32) | $lo, substr($src, 5));
    }
    elsif ($head & 0x04) {
        # 0000 01xx xxxx xxxx xxxx xxxx xxxx xxxx
        # xxxx xxxx xxxx xxxx
        die $msg if length($src) < 6;
        my $hi = (($head & 0x03) << 8) | unpack('C', substr($src, 1, 1));
        my $lo = unpack('N', substr($src, 2, 4));
        return (($hi << 32) | $lo, substr($src, 6));
    }
    elsif ($head & 0x02) {
        # 0000 001x xxxx xxxx xxxx xxxx xxxx xxxx
        # xxxx xxxx xxxx xxxx xxxx xxxx
        die $msg if length($src) < 7;
        my $hi = (($head & 0x01) << 16) | unpack('n', substr($src, 1, 2));
        my $lo = unpack('N', substr($src, 3, 4));
        return (($hi << 32) | $lo, substr($src, 7));
    }
    elsif ($head & 0x01) {
        # 0000 0001 xxxx xxxx xxxx xxxx xxxx xxxx
        # xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        die $msg if length($src) < 8;
        my $hi = unpack('N', substr($src, 0, 4)) & 0x01FFFFFF;
        my $lo = unpack('N', substr($src, 4, 4));
        return (($hi << 32) | $lo, substr($src, 8));
    }
    else {
        die $msg if length($src) < 9;
        my $head2 = unpack('C', substr($src, 1, 1));

        if ($head2 & 0x80) {
            # 0000 0000 1xxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
            # xxxx xxxx
            my $hi = unpack('N', substr($src, 1, 4)) & 0x7FFFFFFF;
            my $lo = unpack('N', substr($src, 5, 4));
            return (($hi << 32) | $lo, substr($src, 9));
        }
        else {
            die 'too big for this encoder to handle';
        }
    }
}

sub _encodeValue {
    my $src = shift;

    if (!defined $src) {
        return "\x00";
    }
    elsif (length(ref $src)) {
        if (blessed $src) {
            die sprintf(
                    "%s#serialize: blessed references are not supported: %s\n",
                    __PACKAGE__,
                    Data::Dumper->new([$src])->Terse(1)->Dump);
        }
        else {
            my $RV = B::svref_2object($src);

            if ($RV->isa('B::AV')) {
                return _encodeArray($src);
            }
            elsif ($RV->isa('B::HV')) {
                return _encodeHash($src);
            }
            else {
                die sprintf(
                        "%s#serialize: unsupported reference type: %s: %s\n",
                        __PACKAGE__,
                        ref $RV,
                        Data::Dumper->new([$src])->Terse(1)->Dump);
            }
        }
    }
    else {
        my $SV = B::svref_2object(\$src);

        if ($SV->isa('B::PV')) {
            if (utf8::is_utf8($src)) {
                my $utf8 = encode_utf8($src);
                return join('', "\x05", _encodeVInt(length $utf8), $utf8);
            }
            else {
                return join('', "\x04", _encodeVInt(length $src ), $src );
            }
        }
        elsif ($SV->isa('B::IV')) {
            if ($src >= 0) {
                return "\x01" . _encodeVInt($src);
            }
            else {
                return "\x02" . _encodeVInt(abs($src));
            }
        }
        elsif ($SV->isa('B::NV')) {
            return _encodeFloat($src);
        }
        else {
            die sprintf(
                    "%s#serialize: unsupported scalar type: %s: %s\n",
                    __PACKAGE__,
                    ref $SV,
                    Data::Dumper->new([$src])->Terse(1)->Dump);
        }
    }
}

sub _encodeArray {
    my $src = shift;

    return join('',
                "\x06",
                _encodeVInt(scalar @$src),
                map { _encodeValue($_) } @$src);
}

sub _decodeArray {
    my $src = shift;

    my ($size, $rest) = _decodeVInt($src);
    my @ret;
    foreach (1 .. $size) {
        my $elem;
        ($elem, $rest) = _decodeValue($rest);
        push @ret, $elem;
    }

    return (\@ret, $rest);
}

sub _encodeHash {
    my $src = shift;

    return join('',
                "\x07",
                _encodeVInt(scalar keys %$src),
                map {
                    _encodeValue($_) => _encodeValue($src->{$_})
                  }
                  keys %$src);
}

sub _decodeHash {
    my $src = shift;

    my ($size, $rest) = _decodeVInt($src);
    my %ret;
    foreach (1 .. $size) {
        my ($key, $val);
        ($key, $rest) = _decodeValue($rest);
        ($val, $rest) = _decodeValue($rest);
        $ret{$key} = $val;
    }

    return (\%ret, $rest);
}

sub _encodeFloat {
    my $src = shift;

    if ($src == 0.0) {
        return "\x03\x80";
    }
    elsif (unpack('f', pack('f', $src)) == $src) {
        # single precision
        return "\x03\x84" . _hton(pack('f', $src));
    }
    elsif (unpack('d', pack('d', $src)) == $src) {
        # double precision
        return "\x03\x88" . _hton(pack('d', $src));
    }
    else {
        # Neither "float" nor "double" can represent the value
        # correctly, so fall back to string.
        return join('', "\x04", _encodeVInt(length $src), $src);
    }
}

sub _decodeFloat {
    my $src = shift;
    my $msg = __PACKAGE__."#deserialize: premature end of value.\n";

    my ($size, $rest) = _decodeVInt($src);
    if ($size == 0) {
        return (0.0, $rest);
    }
    elsif ($size == 4) {
        die $msg if length($rest) < 4;
        return (unpack('f', _ntoh(substr($rest, 0, 4))), substr($rest, 4));
    }
    elsif ($size == 8) {
        die $msg if length($rest) < 8;
        return (unpack('d', _ntoh(substr($rest, 0, 8))), substr($rest, 8));
    }
    else {
        die __PACKAGE__."#deserialize: illegal length of IEEE 754 float.\n";
    }
}

sub _decodeValue {
    my $src = shift;
    my $msg = __PACKAGE__."#deserialize: premature end of value.\n";

    die $msg if !length $src;
    my $type = unpack('C', substr($src, 0, 1));
    my $rest = substr($src, 1);

    if ($type == 0x00) {
        return (undef, $rest);
    }
    elsif ($type == 0x01) {
        return _decodeVInt($rest);
    }
    elsif ($type == 0x02) {
        my $int;
        ($int, $rest) = _decodeVInt($rest);
        return ($int * -1, $rest);
    }
    elsif ($type == 0x03) {
        return _decodeFloat($rest);
    }
    elsif ($type == 0x04) {
        my $size;
        ($size, $rest) = _decodeVInt($rest);
        die $msg if length($rest) < $size;
        return (substr($rest, 0, $size), substr($rest, $size));
    }
    elsif ($type == 0x05) {
        my $size;
        ($size, $rest) = _decodeVInt($rest);
        die $msg if length($rest) < $size;
        return (decode_utf8(substr($rest, 0, $size)), substr($rest, $size));
    }
    elsif ($type == 0x06) {
        return _decodeArray($rest);
    }
    elsif ($type == 0x07) {
        return _decodeHash($rest);
    }
    else {
        die sprintf(
                "%s#deserialize: unknown data type: 0x%02X\n",
                __PACKAGE__, $type);
    }
}

sub _compress {
    my $src = shift;

    my ($d, $status) = deflateInit(-Level => Z_BEST_COMPRESSION);
    die "deflateInit failed with status $status" if $status != Z_OK;

    my $out = $d->deflate($src);
    die "deflate: " . $d->msg if !defined $out;

    my $fin = $d->flush;
    die "flush: " . $d->msg if !defined $fin;

    return $out . $fin;
}

sub _uncompress {
    my $src = shift;

    my ($i, $status) = inflateInit();
    die "inflateInit failed with status $status" if $status != Z_OK;

    my $out;
    ($out, $status) = $i->inflate($src);

    if ($status == Z_STREAM_END) {
        return $out;
    }
    elsif ($status == Z_OK) {
        die __PACKAGE__."#deserialize: premature end of payload.\n";
    }
    else {
        die "deflate: " . $i->msg;
    }
}

=encoding utf-8

=head1 NAME

Tripletail::Serializer - 値の直列化


=head1 SYNOPSIS

    my $ser = $TL->newSerializer();
    $ser->setCryptoKey($key); # must be 32 octets long

    my $bin = $ser->serialize([100, 'foo', {bar => 'baz'}]);
    my $val = $ser->deserialize($bin);
    # $val equals to [100, 'foo', {bar => 'baz'}]


=head1 DESCRIPTION

Perl の各種の値をオクテット列に直列化する。
そのフォーマットは直列化結果が可能な限り小さくなるように設計されており、
また ZLIB 形式による圧縮や AES アルゴリズムによる暗号化、Adler-32
チェックサムによる誤り検出をサポートしている。


=head2 METHODS

=over 4

=item C<< $TL->newSerializer >>

    my $ser = $TL->newSerializer();

L<Tripletail::Serializer> のインスタンスを生成する。引数は取らない。

=cut

use fields qw(cryptoKey);
sub _new {
    my Tripletail::Serializer $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{cryptoKey} = undef;

    return $this;
}


=item C<< getCryptoKey >>

    my $key = $ser->getCryptoKey();

オクテット列表現の暗号化および復号に使用する AES 共通鍵を返す。
もし鍵が設定されていなければ C<undef> を返す。

=cut

sub getCryptoKey {
    my Tripletail::Serializer $this = shift;

    if (defined(my $key = $this->{cryptoKey})) {
        return $key;
    }
    else {
        return;
    }
}


=item C<< setCryptoKey >>

    $ser->setCryptoKey($key);

オクテット列表現の暗号化および復号に使用する AES 共通鍵を設定する。
鍵長は 256 ビット、32 バイトでなければならず、それ以外の長さの鍵を設定しようとした場合には C<die> する。
C<undef> を指定した場合には鍵が設定されていない状態になる。

=cut

sub setCryptoKey {
    my Tripletail::Serializer $this = shift;
    my                        $key  = shift;

    if (defined $key) {
        if (ref $key) {
            die sprintf(
                    "%s#%s: arg[1] is a reference. [%s] (第1引数がリファレンスです)\n",
                    __PACKAGE__, 'setCryptoKey', $key);
        }
        elsif (length($key) != 32) {
            die sprintf(
                    "%s#%s: length of arg[1] is not 32. [%s] (第1引数の長さが32でありません)\n",
                    __PACKAGE__, 'setCryptoKey', $key);
        }
    }

    $this->{cryptoKey} = $key;
    return $this;
}


=item C<< serialize >>

    my $val = [100, 'foo', {bar => 'baz'}];
    my $bin = $ser->serialize($val);

第一引数に与えられた任意の値を直列化する。
もしその中に C<bless> されたリファレンスが存在した場合には die する。
AES 共通鍵が設定されていれば暗号化を行い、されていなければ行わない。

=cut

sub serialize {
    my Tripletail::Serializer $this = shift;
    my                        $src  = shift;

    my $value               = _encodeValue($src);
    my $compressedPayload   = _compress($value);
    my $uncompressedPayload = $value . pack('N', adler32($value));
    my $compLen             = length $compressedPayload;
    my $uncompLen           = length $uncompressedPayload;

    if (defined $this->{cryptoKey}) {
        # The block size in bytes is 16.
        my $isCompressed = ceil($compLen / 16) < ceil($uncompLen / 16);
        my $plainPayload = $isCompressed
                         ? $compressedPayload
                         : $uncompressedPayload;
        my $payload      = $this->_encrypt($plainPayload);
        my $header       = pack('C',
                                IS_ENCRYPTED |
                                  ($isCompressed ? IS_COMPRESSED : HAS_CHECKSUM));
        return $header . $payload;
    }
    else {
        my $isCompressed = $compLen < $uncompLen;
        my $payload      = $isCompressed
                         ? $compressedPayload
                         : $uncompressedPayload;
        my $header       = pack('C',
                                $isCompressed ? IS_COMPRESSED : HAS_CHECKSUM);
        return $header . $payload;
    }
}

sub _encrypt {
    my Tripletail::Serializer $this = shift;
    my                        $src  = shift;

    my $iv     = Crypt::CBC->random_bytes(16);
    my $cipher = Crypt::CBC->new(
                     -literal_key => 1,
                     -key         => $this->{cryptoKey},
                     -cipher      => 'Rijndael',
                     -iv          => $iv,
                     -header      => 'none',
                     -padding     => 'standard'
                    );
    return $iv . $cipher->encrypt($src);
}

sub _decrypt {
    my Tripletail::Serializer $this = shift;
    my                        $src  = shift;

    if (length($src) < 32) {
        die __PACKAGE__."#deserialize: premature end of payload.\n";
    }
    elsif (!defined $this->{cryptoKey}) {
        die __PACKAGE__."#deserialize: AES key is required to decode this.\n";
    }

    my $iv        = substr($src, 0, 16);
    my $encrypted = substr($src, 16);
    my $cipher    = Crypt::CBC->new(
                        -literal_key => 1,
                        -key         => $this->{cryptoKey},
                        -cipher      => 'Rijndael',
                        -iv          => $iv,
                        -header      => 'none',
                        -padding     => 'standard'
                       );
    return $cipher->decrypt($encrypted);
}


=item C<< deserialize >>

    my $val = $ser->deserialize($bin);

第一引数に与えられた、直列化されたデータを元に戻す。

もしデータが暗号化されているならば設定されている AES 共通鍵を用いて復号を行う。
その際に鍵が設定されていなければ die する。

AES 共通鍵が設定されているにもかかわらずデータが暗号化されていない場合にも die する。
この動作はセキュリティ上の理由による。

=cut

sub deserialize {
    my Tripletail::Serializer $this = shift;
    my                        $src  = shift;

    if (!defined $src) {
        die __PACKAGE__."#deserialize: arg[1] is undef.\n";
    }
    elsif (ref $src) {
        die __PACKAGE__."#deserialize: arg[1] is a ref. [$src]\n";
    }
    elsif (!length $src) {
        die __PACKAGE__."#deserialize: arg[1] is an empty string.\n";
    }

    my $header  = unpack('C', substr($src, 0, 1));
    my $payload = substr $src, 1;

    if ($header & 0xF8) {
        die sprintf(
                "%s#deserialize: unrecognizable header: 0x%02X\n",
                __PACKAGE__, $header);
    }
    elsif (!($header & IS_ENCRYPTED) && defined $this->{cryptoKey}) {
        die __PACKAGE__."#deserialize: AES key is provided while".
          " the payload isn't encrypted.\n";
    }

    my $plainPayload = $header & IS_ENCRYPTED
                     ? $this->_decrypt($payload)
                     : $payload;
    my $uncompressed = $header & IS_COMPRESSED
                     ? _uncompress($plainPayload)
                     : $plainPayload;
    my $value        = do {
        if ($header & HAS_CHECKSUM) {
            my ($value, $givenSum) = do {
                my $len = length $uncompressed;
                if ($len >= 4) {
                    ( substr($uncompressed, 0, $len - 4),
                      substr($uncompressed, $len - 4, 4) );
                }
                else {
                    die __PACKAGE__."#deserialize: premature end of payload.\n";
                }
            };
            my $actualSum = pack('N', adler32($value));
            if ($givenSum eq $actualSum) {
                $value;
            }
            else {
                die __PACKAGE__."#deserialize: checksum mismatched.\n";
            }
        }
        else {
            $uncompressed;
        }
    };
    my ($ret, $rest) = _decodeValue($value);
    if (length $rest) {
        die __PACKAGE__."#deserialize: garbage at the end of payload.\n";
    }
    return $ret;
}

=back


=head2 FORMAT

本クラスで用いる直列化のフォーマットを以下に述べる。それには主として
RFC 4234 (L<http://tools.ietf.org/html/rfc4234>)
を用いるが、ビット表現については EBML RFC Draft
(L<http://matroska.org/technical/specs/rfc/index.html>)
のものを使用する。

    document = header payload

直列化結果（以下ドキュメント）はヘッダとペイロードから成る。

    header        = 5%b0 is-encrypted is-compressed has-checksum
    is-encrypted  = BIT
    is-compressed = BIT
    has-checksum  = BIT

ヘッダ長は 1 オクテットであり、その上位 5 ビットは常にゼロである。
C<is-encrypted> ビットは後述の暗号化が行われているかどうかを、
C<is-compressed> ビットは圧縮されているかどうかを、
C<has-checksum> ビットは Adler-32 チェックサムが存在するかどうかを示す。
ただし C<is-compressed> と C<has-checksum> は排他である。

    payload              = encrypted-payload / plain-payload

    encrypted-payload    = iv AES-CBC(plain-payload)
    iv                   = 16OCTET

    plain-payload        = compressed-payload / uncompressed-payload
    compressed-payload   = ZLIB(value)
    uncompressed-payload = value-with-checksum / value
    value-with-checksum  = value ADLER32(value)

ペイロードには次の 6 種類がある。

=over 4

=item 暗号化され、圧縮されている

暗号化には AES アルゴリズムの CBC モードを使用する。鍵長は 256 ビット、ブロック長は 128 ビットである。
IV はランダムな 16 オクテットであり、パディングには PKCS#7
(L<http://tools.ietf.org/html/rfc5652#section-6.3>) 形式を用いる。

=item 暗号化され、圧縮されておらず、チェックサムが存在する

チェックサムには Adler-32 (L<http://tools.ietf.org/html/rfc1950#section-8>)
アルゴリズムを用いる。これは network byte order の 4 オクテットで記録される。

=item 暗号化され、圧縮されておらず、チェックサムも存在しない

この形式では誤った鍵を用いてペイロードを復号した場合にエラーになる事を保証できないため推奨されない。

=item 暗号化されておらず、圧縮されている

圧縮には RFC 1950 (L<http://tools.ietf.org/html/rfc1950>) ZLIB 形式を用いる。
この場合 ZLIB 形式の定義により必ずその内部に Adler-32 チェックサムが存在する。
従って圧縮されている場合には独立のチェックサムが付けられる事は無い。

=item 暗号化も圧縮もされておらず、チェックサムが存在する

この形式は ZLIB 圧縮すると却って結果が肥大化する場合に限って用いられる。

=item 暗号化も圧縮もされておらず、チェックサムも存在しない

この形式では不正なペイロードを L</"deserialize"> した場合にエラーになる事を保証できないため推奨されない。

=back

    value = %x00                     ; undef
          / %x01 vint                ; non-negative integer
          / %x02 vint                ; negative integer
          / %x03 size *OCTET         ; IEEE 754 floating point number
          / %x04 size *OCTET         ; octet string
          / %x05 size *OCTET         ; UTF-8 string
          / %x06 size *value         ; array
          / %x07 size *(value value) ; hash

整数および浮動小数点数は、それを表現するために必要な最小のオクテット数を用いて network byte order で格納される。
整数の幅は任意だが、浮動小数点数の幅は 0, 4, 8 オクテットのいずれかでなければならない。
幅ゼロの整数は 0 を、幅ゼロの浮動小数点数は 0.0 をそれぞれ表す。

負の整数はその絶対値で表現する。

ハッシュテーブルは複数個のキーと値のペアで表現されるが、そのキーには整数、オクテット列、UTF-8 文字列のみが使用可能である。

    size = vint
    vint = ( %b0 vint 7BIT ) / ( %b1 7BIT )

整数およびデータ長は可変長整数で表現される。その形式は EBML RFC Draft
"2.1. Variable size integer"
(L<http://matroska.org/technical/specs/rfc/index.html>)
に定義されたものと同一である。例:

    Width  Size  Representation
      1    2^7   1xxx xxxx
      2    2^14  01xx xxxx  xxxx xxxx
      3    2^21  001x xxxx  xxxx xxxx  xxxx xxxx
      4    2^28  0001 xxxx  xxxx xxxx  xxxx xxxx  xxxx xxxx


=head1 AUTHOR INFORMATION

Copyright 2006-2012 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site: http://tripletail.jp/

=cut

1;
