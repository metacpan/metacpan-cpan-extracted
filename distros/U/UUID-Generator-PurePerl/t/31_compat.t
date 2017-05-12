use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 20;

eval q{ require UUID::Generator::PurePerl::Compat; };
die if $@;

# Data::UUID's binary and base64 represenatation is platform-dependent.
# So at first, detect endian;
my $endian;
if (0) {}
elsif (pack('L', 0xDEADBEAF) eq pack('V', 0xDEADBEAF)) {
    # little endian; eg. x86, x86_64, etc
    $endian = 'little';
}
elsif (pack('L', 0xDEADBEAF) eq pack('N', 0xDEADBEAF)) {
    # big endian; eg. sparc, powerpc, s390, etc
    $endian = 'big';
}
else {
    die "mal-endian";
}

my %upns;
$upns{dns}  = UUID::Generator::PurePerl::Compat::NameSpace_DNS();
$upns{url}  = UUID::Generator::PurePerl::Compat::NameSpace_URL();
$upns{oid}  = UUID::Generator::PurePerl::Compat::NameSpace_OID();
$upns{x500} = UUID::Generator::PurePerl::Compat::NameSpace_X500();

my $ug = UUID::Generator::PurePerl::Compat->new();

# creates binary (16 byte long binary value) UUID.
ok( $ug->create() =~ m{ \A [\x00-\xff]{16} \z }xmso, 'create()' );
ok( $ug->create_bin() =~ m{ \A [\x00-\xff]{16} \z }xmso, 'create_bin()' );

# creates binary (16-byte long binary value) UUID based on particular
# namespace and name string.
my $v3_bin = pack 'LSSH*H*', 0x3d813cbb, 0x47fb, 0x32ba, '91df', '831e1593ac29';
#                  ^^^^^^^ endian safe representation :)
is( $ug->create_from_name($upns{dns}, 'www.widgets.com'), $v3_bin, 'create_from_name()' );
is( $ug->create_from_name_bin($upns{dns}, 'www.widgets.com'), $v3_bin, 'create_from_name_bin()' );

# creates UUID string, using conventional UUID string format,
# such as: 4162F712-1DD2-11B2-B17E-C09EFE1DC403
ok( uc $ug->create_str() =~ m{ \A [0-9A-F]{8} (?: - [0-9A-F]{4} ){3} - [0-9A-F]{12} \z }xmso, 'create_str()' );
is( uc $ug->create_from_name_str($upns{dns}, 'www.widgets.com'), '3D813CBB-47FB-32BA-91DF-831E1593AC29', 'create_from_name_str()' );

# creates UUID string as a hex string,
# such as: 0x4162F7121DD211B2B17EC09EFE1DC403
ok( $ug->create_hex() =~ m{ \A 0x [0-9A-F]{32} \z }ixmso, 'create_hex()' );
is( uc $ug->create_from_name_hex($upns{dns}, 'www.widgets.com'), '0X3D813CBB47FB32BA91DF831E1593AC29', 'create_from_name_hex()' );

# creates UUID string as a Base64-encoded string
ok( $ug->create_b64() =~ m{ \A [+/0-9A-Za-z]{22} [=+/0-9A-Za-z]{2} \s* \z }xmso, 'create_b64()' );
if ($endian eq 'little') {
    is( $ug->create_from_name_b64($upns{dns}, 'www.widgets.com'), 'uzyBPftHujKR34MeFZOsKQ==', 'create_from_name_b64()' );
}
else {
    is( $ug->create_from_name_b64($upns{dns}, 'www.widgets.com'), 'PYE8u0f7MrqR34MeFZOsKQ==', 'create_from_name_b64()' );
}


# convert to conventional string representation
is( uc $ug->to_string($ug->create_from_name_bin($upns{dns}, 'www.widgets.com')), '3D813CBB-47FB-32BA-91DF-831E1593AC29', 'to_string()' );

# convert to hex string
is( uc $ug->to_hexstring($ug->create_from_name_bin($upns{dns}, 'www.widgets.com')), '0X3D813CBB47FB32BA91DF831E1593AC29', 'to_hexstring()' );

# convert to Base64-encoded string
ok( $ug->to_b64string($ug->create_bin()) =~ m{ \A [+/0-9A-Za-z]{22} [=+/0-9A-Za-z]{2} \s* \z }xmso, 'to_b64string()' );
if ($endian eq 'little') {
    is( $ug->to_b64string($ug->create_from_name_bin($upns{dns}, 'www.widgets.com')), 'uzyBPftHujKR34MeFZOsKQ==', 'to_b64string()' );
}
else {
    is( $ug->to_b64string($ug->create_from_name_bin($upns{dns}, 'www.widgets.com')), 'PYE8u0f7MrqR34MeFZOsKQ==', 'to_b64string()' );
}


# recreate binary UUID from string
is( $ug->from_string($ug->create_from_name_str($upns{dns}, 'www.widgets.com')), $v3_bin, 'from_string()' );
is( $ug->from_hexstring($ug->create_from_name_hex($upns{dns}, 'www.widgets.com')), $v3_bin, 'from_hexstring()' );

# recreate binary UUID from Base64-encoded string
is( $ug->from_b64string($ug->create_from_name_b64($upns{dns}, 'www.widgets.com')), $v3_bin, 'from_b64string()' );

# returns -1, 0 or 1 depending on whether uuid1 less
# than, equals to, or greater than uuid2
ok( $ug->compare($upns{dns}, $upns{dns}) == 0, 'compare() ==' );
ok( $ug->compare($upns{dns}, $upns{url}) < 0, 'compare() <' );
ok( $ug->compare($upns{url}, $upns{dns}) > 0, 'compare() >' );

