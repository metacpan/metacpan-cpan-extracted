use inc::Module::Install;
use Devel::CheckLib;
use Getopt::Long;
use File::Spec::Functions;

BEGIN {
    if ( $Module::Install::AUTHOR ) {
        use Module::Install::XSUtil;
    }
}

my $headdir;
my $libdir;
my $prefix;
my $randomize;

GetOptions(
    'headers=s'  => \$headdir,
    'libs=s'     => \$libdir,
    'prefix=s'   => \$prefix,
    'randomize!' => \$randomize,
);

if ( $prefix ) {
    $headdir = catdir( $prefix, 'include' );
    $libdir  = catdir( $prefix, 'lib' );
}

cc_include_paths( $headdir ) if $headdir;
cc_libs( '-L' . $libdir ) if $libdir;

cc_include_paths( 'include' );

name 'Zonemaster-LDNS';
version_from 'lib/Zonemaster/LDNS.pm';
perl_version_from 'lib/Zonemaster/LDNS.pm';
license 'bsd';
author 'Calle Dybedahl <calle@init.se>';
author 'Mattias P <mattias.paivarinta@iis.se>';
abstract 'Perl wrapper for the ldns DNS library.';

configure_requires 'Devel::CheckLib';
requires 'MIME::Base64';
test_requires 'JSON::PP';
test_requires 'Test::Fatal';

use_ppport 3.19;
cc_libs 'crypto';
cc_src_paths 'src';

my %assert_args = (
    lib      => 'crypto',
    header   => 'openssl/crypto.h',
    function => 'if(SSLeay()) return 0; else return 1;'
);
$assert_args{LIBS} = '-L' . $libdir  if $libdir;
$assert_args{INC}  = '-I' . $headdir if $headdir;

cc_assert_lib %assert_args;

if (not check_ecdsa(%assert_args)) {
    print "Your OpenSSL does not seem to support ECDSA.\n";
    exit;
}
else {
    print "ECDSA support detected.\n";
}

if (not check_gost(%assert_args)) {
    print "Your OpenSSL does not seem to support GOST.\n";
}
else {
    print "GOST support detected.\n";
    cc_define '-DUSE_GOST';
}

if (
    check_lib(
        lib      => 'idn',
        header   => 'idna.h',
        function => 'if(strcmp(IDNA_ACE_PREFIX,"xn--")==0) return 0; else return 1;'
    )
  )
{
    cc_libs 'idn';
    cc_define '-DWE_CAN_HAZ_IDN';
    print "IDNA support detected.\n";
}

if ( $randomize ) {
    cc_define '-DRANDOMIZE';
    print( ( "=" x 65 ) . "\n" );
    print "Compiling with randomzied capitalization.\n";
    print( ( "=" x 65 ) . "\n" );
}

sub MY::postamble {
    return <<'TARGET';
CONTRIBUTORS.txt:
	@( \
	echo "This module is based on the ldns library from NLnet Labs <https://www.nlnetlabs.nl/projects/ldns/>" ; \
    echo ; \
	echo "Contributors to this module:" ; \
	git shortlog -sne | cut -b8- \
	) >| CONTRIBUTORS.txt
TARGET
}

WriteAll;

sub check_ecdsa {
    my %args = @_;

    $args{header} = [ 'openssl/crypto.h', 'openssl/ecdsa.h' ];
    $args{function} = q[if(ECDSA_SIG_new()) return 0; else return 1;];

    return check_lib(%args);
}

sub check_gost {
    my %args = @_;

    $args{header} = [ 'openssl/crypto.h', 'openssl/ecdsa.h', 'openssl/engine.h' ];
    $args{function} = <<'CODE';
    const EVP_PKEY_ASN1_METHOD* meth;
    ENGINE* e;

    meth = EVP_PKEY_asn1_find_str(NULL, "gost2001", -1);
    if(meth) {
       return 0;
    }

    e = ENGINE_by_id("gost");
    if(!e) {
       ENGINE_load_builtin_engines();
       ENGINE_load_dynamic();
       e = ENGINE_by_id("gost");
    }
    if(!e) {
       return 1;
    }
    if(!ENGINE_set_default(e, ENGINE_METHOD_ALL)) {
       return 1;
    }

    meth = EVP_PKEY_asn1_find_str(&e, "gost2001", -1);
    if(!meth) {
       return 1;
    }

    return 0;

CODE

    return check_lib(%args);
}
