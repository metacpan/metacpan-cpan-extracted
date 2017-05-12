use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

eval q{ use Data::UUID };
plan skip_all => 'Data::UUID is not installed', 4  if $@;

eval q{ use UUID::Generator::PurePerl;
        require UUID::Generator::PurePerl::Compat; };
die if $@;

my $bad_du_md5;

eval q{ use version };
if ($@) {
    eval {
        if (0+$Data::UUID::VERSION < 1.200) {
            $bad_du_md5 = 1;
        }
    };
    if ($@) {
        $bad_du_md5 = 1;
    }
}
else {
    my $du_ver = version->new($Data::UUID::VERSION);
    if ($du_ver lt '1.200') {
        $bad_du_md5 = 1;
    }
}

plan tests => 18;

# in this test script, NameSpace_DNS etc cannot be used.  why?
sub du_const {
    my $name = shift;
    return Data::UUID::constant($name, 0);
}

my %duns;
#$duns{dns} = Data::UUID::NameSpace_DNS();
$duns{dns}  = du_const('NameSpace_DNS');
$duns{url}  = du_const('NameSpace_URL');
$duns{oid}  = du_const('NameSpace_OID');
$duns{x500} = du_const('NameSpace_X500');

my %upns;
$upns{dns}  = UUID::Generator::PurePerl::Compat::NameSpace_DNS();
$upns{url}  = UUID::Generator::PurePerl::Compat::NameSpace_URL();
$upns{oid}  = UUID::Generator::PurePerl::Compat::NameSpace_OID();
$upns{x500} = UUID::Generator::PurePerl::Compat::NameSpace_X500();

my $ug = UUID::Generator::PurePerl::Compat->new();
my $du = Data::UUID->new();

my $t;

SKIP: {
    skip "Data::UUID ${Data::UUID::VERSION} has wrong MD5 implementation", 11
        if $bad_du_md5;

# creates binary (16-byte long binary value) UUID based on particular
# namespace and name string.
is( $ug->create_from_name($upns{dns}, 'www.widgets.com'), $du->create_from_name($duns{dns}, 'www.widgets.com'), 'create_from_name()' );
is( $ug->create_from_name_bin($upns{dns}, 'www.widgets.com'), $du->create_from_name($duns{dns}, 'www.widgets.com'), 'create_from_name_bin()' );

# creates UUID string, using conventional UUID string format,
# such as: 4162F712-1DD2-11B2-B17E-C09EFE1DC403
is( uc $ug->create_from_name_str($upns{dns}, 'www.widgets.com'), uc $du->create_from_name_str($duns{dns}, 'www.widgets.com'), 'create_from_name_str()' );

# creates UUID string as a hex string,
# such as: 0x4162F7121DD211B2B17EC09EFE1DC403
is( uc $ug->create_from_name_hex($upns{dns}, 'www.widgets.com'), uc $du->create_from_name_hex($duns{dns}, 'www.widgets.com'),, 'create_from_name_hex()' );

# creates UUID string as a Base64-encoded string
is( $ug->create_from_name_b64($upns{dns}, 'www.widgets.com'), $du->create_from_name_b64($duns{dns}, 'www.widgets.com'), 'create_from_name_b64()' );


$t = $du->create_from_name_bin($duns{dns}, 'www.widgets.com');
# convert to conventional string representation
is( uc $ug->to_string($t), uc $du->to_string($t), 'to_string()' );

# convert to hex string
is( uc $ug->to_hexstring($t), uc $du->to_hexstring($t), 'to_hexstring()' );

# convert to Base64-encoded string
is( $ug->to_b64string($t), $du->to_b64string($t), 'to_b64string()' );


# recreate binary UUID from string
$t = $du->create_from_name_str($duns{dns}, 'www.widgets.com');
is( $ug->from_string($t), $du->from_string($t), 'from_string()' );
$t = $du->create_from_name_hex($duns{dns}, 'www.widgets.com');
is( $ug->from_hexstring($t), $du->from_hexstring($t), 'from_hexstring()' );

# recreate binary UUID from Base64-encoded string
$t = $du->create_from_name_b64($duns{dns}, 'www.widgets.com');
is( $ug->from_b64string($t), $du->from_b64string($t), 'from_b64string()' );

};

# returns -1, 0 or 1 depending on whether uuid1 less
# than, equals to, or greater than uuid2
ok( ( $ug->compare($upns{dns}, $upns{dns}) | $ug->compare($duns{dns}, $duns{dns}) ) == 0, 'compare() ==' );
ok( ( $ug->compare($upns{dns}, $upns{url}) * $ug->compare($duns{dns}, $duns{url}) ) > 0, 'compare() <' );
ok( ( $ug->compare($upns{url}, $upns{dns}) * $ug->compare($duns{url}, $duns{dns}) ) > 0, 'compare() >' );


is( $upns{dns},  $duns{dns},  'NameSpace_DNS' );
is( $upns{url},  $duns{url},  'NameSpace_URL' );
is( $upns{oid},  $duns{oid},  'NameSpace_OID' );
is( $upns{x500}, $duns{x500}, 'NameSpace_X500' );

