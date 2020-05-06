use inc::Module::Install;
use Devel::CheckLib;
use Getopt::Long;
use File::Spec::Functions;

BEGIN {
    if ( $Module::Install::AUTHOR ) {
        use Module::Install::XSUtil;
    }
}

name 'Zonemaster-LDNS';
all_from 'lib/Zonemaster/LDNS.pm';
repository 'https://github.com/zonemaster/zonemaster-ldns';
bugtracker 'https://github.com/zonemaster/zonemaster-ldns/issues';

my $opt_ed25519        = 1;
my $opt_idn            = 1;
my $opt_internal_ldns  = 1;
my $opt_randomize      = 0;
my $opt_prefix_openssl = "";
GetOptions(
    'ed25519!'         => \$opt_ed25519,
    'idn!'             => \$opt_idn,
    'internal-ldns!'   => \$opt_internal_ldns,
    'randomize!'       => \$opt_randomize,
    'prefix-openssl=s' => \$opt_prefix_openssl,
);

configure_requires 'Devel::CheckLib';
configure_requires 'Module::Install' => 1.19;
configure_requires 'Module::Install::XSUtil';
test_requires 'JSON::PP';
test_requires 'Test::Fatal';
test_requires 'Test::More' => 1.302015;

use_ppport 3.19;
cc_include_paths 'include';
cc_src_paths 'src';


# OpenSSL

my %assert_lib_args_openssl;
if ( $opt_prefix_openssl ) {
    print "Custom prefix for OpenSSL: $opt_prefix_openssl\n";
    cc_include_paths "$opt_prefix_openssl/include";
    cc_libs "-L$opt_prefix_openssl/lib", "crypto";
    $assert_lib_args_openssl{incpath} = "$opt_prefix_openssl/include";
    $assert_lib_args_openssl{libpath} = "$opt_prefix_openssl/lib";
}
else {
    cc_libs 'crypto';
}

cc_assert_lib(
    lib      => 'crypto',
    header   => 'openssl/crypto.h',
    function => 'if(SSLeay()) return 0; else return 1;',
    %assert_lib_args_openssl,
);
if ( $opt_ed25519 ) {
    print "Feature Ed25519 enabled\n";
    cc_assert_lib(
        lib      => 'crypto',
        header   => 'openssl/evp.h',
        function => 'EVP_PKEY_ED25519; return 0;',
        %assert_lib_args_openssl,
    );
}
else {
    print "Feature Ed25519 disabled\n";
}


# LDNS

if ( $opt_internal_ldns ) {
    print "Feature internal ldns enabled\n";
    cc_libs '-Lldns/lib';
    cc_include_paths 'ldns';
}
else {
    print "Feature internal ldns disabled\n";
    cc_libs 'ldns';
    if ( $opt_ed25519 ) {
        cc_assert_lib(
            lib      => 'ldns',
            header   => 'ldns/ldns.h',
            ccflags  => '-DUSE_ED25519',
            function => 'if(LDNS_ED25519) return 0; else return 1;'
        );
    }
}


# IDN

if ( $opt_idn ) {
    print "Feature idn enabled\n";
    check_lib_or_exit(
        lib    => 'idn',
        header => 'idna.h',
        function =>
          'if(strcmp(IDNA_ACE_PREFIX,"xn--")==0) return 0; else return 1;'
    );
    cc_libs 'idn';
    cc_define '-DWE_CAN_HAZ_IDN';
}
else {
    print "Feature idn disabled\n";
}


# Internals

if ( $opt_randomize ) {
    print "Feature randomized capitalization enabled\n";
    cc_define '-DRANDOMIZE';
}
else {
    print "Feature randomized capitalization disabled\n";
}


sub MY::postamble {

    my $contributors_make = <<'END_CONTRIBUTORS';

CONTRIBUTORS.txt:
	@( \
	echo "This module is based on the ldns library from NLnet Labs <https://www.nlnetlabs.nl/projects/ldns/>" ; \
    echo ; \
	echo "Contributors to this module:" ; \
	git shortlog -sne | cut -b8- \
	) >| CONTRIBUTORS.txt

END_CONTRIBUTORS

    my $configure_flags_make = <<'END_CONFIGURE_FLAGS';

CONFIGURE_FLAGS += --disable-ldns-config --disable-dane

END_CONFIGURE_FLAGS

    my $openssl_make = <<END_ED25519;

CONFIGURE_FLAGS += --with-ssl=$opt_prefix_openssl

END_ED25519

    my $ed25519_make = <<'END_ED25519';

CONFIGURE_FLAGS += --enable-ed25519

END_ED25519

    my $no_ed25519_make = <<'END_NO_ED25519';

CONFIGURE_FLAGS += --disable-ed25519

END_NO_ED25519

    my $internal_ldns_make = <<'END_INTERNAL_LDNS';

LDFROM += ldns/.libs/libldns.a

config :: ldns/.libs/libldns.a

ldns/.libs/libldns.a: ldns/configure
	cd ldns ;\
	./configure CFLAGS=-fPIC $(CONFIGURE_FLAGS) ;\
	make lib

ldns/configure:
	git submodule init
	git submodule sync
	git submodule update
	cd ldns ; libtoolize -ci
	cd ldns ; autoreconf -fi

END_INTERNAL_LDNS

    my $postamble = '';

    $postamble .= $contributors_make;
    if ( $opt_internal_ldns ) {
        $postamble .= $configure_flags_make;
        $postamble .= $openssl_make if $opt_prefix_openssl;
        $postamble .= $ed25519_make if $opt_ed25519;
        $postamble .= $no_ed25519_make if !$opt_ed25519;
        $postamble .= $internal_ldns_make;
    }

    return $postamble;
}

sub MY::test_via_harness {
    local $_ = shift()->MM::test_via_harness(@_);
    s/\bPERL_DL_NONLAZY=1 +//g;
    return $_;
}

sub MY::test_via_script {
    local $_ = shift()->MM::test_via_script(@_);
    s/\bPERL_DL_NON_LAZY=1 +//g;
    return $_;
}

WriteAll;
