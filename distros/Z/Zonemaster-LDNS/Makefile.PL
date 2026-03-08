use v5.14;

use inc::Module::Install;
use Devel::CheckLib;
use ExtUtils::PkgConfig;
use File::Spec::Functions;
use Getopt::Long;

BEGIN {
    if ( $Module::Install::AUTHOR ) {
        use Module::Install::XSUtil;
    }
}

name 'Zonemaster-LDNS';
all_from 'lib/Zonemaster/LDNS.pm';
repository 'https://github.com/zonemaster/zonemaster-ldns';
bugtracker 'https://github.com/zonemaster/zonemaster-ldns/issues';

=head1 Optional features

=over

=item --[no-]ed25519

Enable (or disable) support for Ed25519 in both openssl and ldns.
Enabled by default.

=item --[no-]idn

Enable (or disable) support for converting IDN labels in U-label format (with
non-ASCII Unicode characters) to the same IDN labels in A-label format (encoded
in ASCII).
Enabled by default.

=item --[no-]internal-ldns

When enabled, an included version of ldns is statically linked into
Zonemaster::LDNS.
When disabled, libldns is dynamically linked just like other dependencies.
Enabled by default.

=item --prefix-openssl=PATH

Search for OpenSSL headers and libraries in PATH.
The LDNS script will look for an "include" and a "lib" folder.

=item --openssl-inc=PATH

Search for OpenSSL include in PATH.
The PATH is passed to the LDNS compiler via the CFLAGS variable.

=item --openssl-lib=PATH

Search for OpenSSL library in PATH.
The PATH is passed to the LDNS compiler via the LDFLAGS variable.

=item --libidn-inc=PATH

Search for Libidn include in PATH.

=item --libidn-lib=PATH

Search for Libidn library in PATH.

=item --ldns-inc=PATH

Search for LDNS include in PATH.

=item --ldns-lib=PATH

Search for LDNS library in PATH.

=item --debug

Enable debug mode, more verbose output.

=back

=cut

my $opt_ed25519       = 1;
my $opt_idn           = 1;
my $opt_internal_ldns = 1;
my $opt_debug         = 0;
my $opt_assets        = {
    openssl => {
        prefix => "",
        inc    => "",
        lib    => ""
    },
    ldns => {
        inc => "",
        lib => ""
    },
    libidn => {
        inc => "",
        lib => ""
    }
};

GetOptions(
    'ed25519!'         => \$opt_ed25519,
    'idn!'             => \$opt_idn,
    'internal-ldns!'   => \$opt_internal_ldns,
    'debug!'           => \$opt_debug,
    'prefix-openssl=s' => \$$opt_assets{openssl}{prefix},
    'openssl-inc=s'    => \$$opt_assets{openssl}{inc},
    'openssl-lib=s'    => \$$opt_assets{openssl}{lib},
    'libidn-inc=s'     => \$$opt_assets{libidn}{inc},
    'libidn-lib=s'     => \$$opt_assets{libidn}{lib},
    'ldns-inc=s'       => \$$opt_assets{ldns}{inc},
    'ldns-lib=s'       => \$$opt_assets{ldns}{lib},
);

perl_version '5.026000';    # Perl v5.26.0 or higher is required for installation.

configure_requires 'Devel::CheckLib'         => 0;
configure_requires 'ExtUtils::PkgConfig'     => 0;
configure_requires 'Module::Install'         => 1.19;
configure_requires 'Module::Install::XSUtil' => 0;
#
test_requires 'JSON::PP'          => 0;
test_requires 'MIME::Base32'      => 0;
test_requires 'Test::Fatal'       => 0;
test_requires 'Test::Differences' => 0;
test_requires 'Test::Exception'   => 0;
test_requires 'Test::More'        => 1.302015;
test_requires 'Test::NoWarnings'  => 0;

use_ppport 3.19;
cc_include_paths 'include';
cc_src_paths 'src';

my %assert_lib_args = (
    openssl => {},
    libidn  => {},
    ldns    => {}
);

sub custom_assets {
    my ( $href ) = @_;

    # $href = { key => "openssl", lib => "crypto", name => "OpenSSL" }

    my $key    = $href->{key};
    my $name   = $href->{name};
    my $lib    = $href->{lib};
    my $pcname = $href->{pcname};

    my $input_prefix = $opt_assets->{$key}{prefix};
    my $input_inc    = $opt_assets->{$key}{inc};
    my $input_lib    = $opt_assets->{$key}{lib};

    my $custom_lib = ( $input_prefix or $input_inc or $input_lib );
    if ( $custom_lib ) {
        my $incpath = "";
        my $libpath = "";

        if ( $input_prefix ) {
            print "Custom prefix for $name: $input_prefix\n";
            $incpath = "$input_prefix/include";
            $libpath = "$input_prefix/lib";
        }

        if ( $input_inc ) {
            print "Custom include directory for $name: $input_inc\n";
            $incpath = "$input_inc";
        }

        if ( $input_lib ) {
            print "Custom library directory for $name: $input_lib\n";
            $libpath = "$input_lib";
        }

        cc_include_paths "$incpath";
        cc_libs "-L$libpath", "$lib";

        $assert_lib_args{$key}{incpath} = "$incpath";
        $assert_lib_args{$key}{libpath} = "$libpath";
    } ## end if ( $custom_lib )
    else {
        my %pkg_info = eval { ExtUtils::PkgConfig->find( $pcname ); };
        if ( $@ ) {
            warn "$@\n";
            say "Guessing LDFLAGS for $name: -l${lib}";
            cc_libs $lib;
        }
        else {
            if ( ( my $cflags = $pkg_info{cflags} ) ne '' ) {
                say "Adding CFLAGS for $name using pkg-config: $cflags";
                cc_include_paths $cflags;
            }
            if ( ( my $libs = $pkg_info{libs} ) ne '' ) {
                say "Adding LDFLAGS for $name using pkg-config: $libs";
                cc_libs $libs;
            }
        }
    }
} ## end sub custom_assets

# OpenSSL

custom_assets(
    {
        name   => "OpenSSL",
        lib    => "crypto",
        key    => "openssl",
        pcname => "openssl"
    }
);

cc_assert_lib(
    debug    => $opt_debug,
    lib      => 'crypto',
    header   => 'openssl/crypto.h',
    function => 'if(SSLeay()) return 0; else return 1;',
    %{ $assert_lib_args{openssl} },
);
if ( $opt_ed25519 ) {
    print "Feature Ed25519 enabled\n";
    cc_assert_lib(
        debug    => $opt_debug,
        lib      => 'crypto',
        header   => 'openssl/evp.h',
        function => 'EVP_PKEY_ED25519; return 0;',
        %{ $assert_lib_args{openssl} },
    );
}
else {
    print "Feature Ed25519 disabled\n";
}

# LDNS and NSID

my $ldns_has_nsid;

if ( $opt_internal_ldns ) {
    print "Feature internal ldns enabled\n";
    cc_libs '-Lldns/lib';
    cc_include_paths 'ldns';
    $ldns_has_nsid = 1;
}
else {
    print "Feature internal ldns disabled\n";

    custom_assets(
        {
            name   => "LDNS",
            lib    => "ldns",
            key    => "ldns",
            pcname => "libldns"
        }
    );

    if ( $opt_ed25519 ) {
        cc_assert_lib(
            debug  => $opt_debug,
            lib    => 'ldns',
            header => 'ldns/ldns.h',
            %{ $assert_lib_args{ldns} },
            ccflags  => '-DUSE_ED25519',
            function => 'if(LDNS_ED25519) return 0; else return 1;'
        );
    }

    # NSID feature requires LDNS version >= 1.8.2
    $ldns_has_nsid = check_lib(
        debug  => $opt_debug,
        lib    => 'ldns',
        header => 'ldns/util.h',
        %{ $assert_lib_args{ldns} },
        function => 'if ( LDNS_REVISION >= ((1<<16)|(8<<8)|(2)) ) return 0; else return 1;'
    );
} ## end else [ if ( $opt_internal_ldns)]

if ( $ldns_has_nsid ) {
    print "Feature NSID enabled\n";
    cc_define '-DNSID_SUPPORT';
}
else {
    print "Feature NSID disabled\n";
}

# Libidn

if ( $opt_idn ) {
    print "Feature idn enabled\n";

    custom_assets(
        {
            name   => "Libidn",
            lib    => "idn2",
            key    => "libidn",
            pcname => "libidn2"
        }
    );

    check_lib_or_exit(
        debug  => $opt_debug,
        lib    => 'idn2',
        header => 'idn2.h',
        %{ $assert_lib_args{libidn} },
        function => 'return IDN2_OK;'
    );
    cc_define '-DWE_CAN_HAZ_IDN';
} ## end if ( $opt_idn )
else {
    print "Feature idn disabled\n";
}

# OpenSSL with SHA-1 support

check_lib(
    header   => [ 'openssl/crypto.h', 'openssl/evp.h', 'openssl/x509.h' ],
    lib      => 'crypto',
    function => q{
        /* 2048-bit RSA public key in DER format. */
        static const unsigned char pubkey_der[] =
          "\x30\x82\x01\x22\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01"
          "\x01\x05\x00\x03\x82\x01\x0f\x00\x30\x82\x01\x0a\x02\x82\x01\x01"
          "\x00\x9c\x46\x86\x8a\x41\xf0\x8c\x69\x47\xc6\x88\xaf\x53\x82\x21"
          "\xb2\x91\x39\xc3\xcd\xfe\x02\xcb\x2a\xb3\xe2\x18\x09\xa0\x3c\x9f"
          "\x8f\x87\x90\x7b\xcf\xb7\x53\xdd\x12\x80\x4b\x9a\x12\x3f\x2d\xae"
          "\xd0\x88\x7d\x43\x77\x92\xfd\xcb\x02\x82\x48\xed\x6c\xe2\x2f\x5f"
          "\xef\xc3\xaa\x0e\xc4\x69\x18\x73\x52\x99\x48\x84\x53\x19\xa2\x52"
          "\x2f\x0c\x03\xdc\xa7\x3b\xd3\x74\x44\x20\x18\x10\x78\xaa\xd2\x87"
          "\xe2\xc3\xe2\xd6\x08\x02\x2e\xd7\x86\x9f\x75\x3a\x8d\x71\x62\x1c"
          "\xeb\x50\x23\xb4\x11\x39\x2c\xf2\xec\x20\x53\xcd\x0f\x12\x92\xa4"
          "\xaf\x9b\x07\xa5\x21\x73\x89\x70\x6c\x9b\x7a\xda\x1c\x12\x12\xd1"
          "\xe4\x4b\xc7\xcf\x13\xe5\xbd\xa6\xc3\x7d\xde\xb7\x53\x52\x17\x29"
          "\x46\xba\x8e\xf9\x7d\xe4\x29\xe6\xaf\x6b\x07\x2f\x69\x68\x6e\x43"
          "\x7e\x3a\xb3\xcf\xea\x22\xed\xd1\xbe\x28\x15\x70\x2e\xa2\x0a\x8c"
          "\x9a\x77\xac\x56\xfc\x26\x14\x4d\x39\xa3\x4e\x68\x80\x04\x6e\x35"
          "\x15\xab\xbf\x12\x0f\xd3\xc3\x92\xa8\x65\x91\x3e\xd0\x12\x59\xd4"
          "\x6e\x25\xfa\x87\x3a\x55\x52\xf3\xe6\x80\x17\x28\x1e\xc5\x57\xc8"
          "\x63\x2f\x74\x0b\x91\x40\x27\x75\xef\xfe\xa1\xe5\x93\x77\xc8\xc3"
          "\x3d\x02\x03\x01\x00\x01";

        static const unsigned char corpus[] = "sha1 signature probe\n";

        /* SHA-1 digest of corpus, signed with the private key of pubkey_der */
        static const unsigned char signature[] =
          "\x54\xb2\x10\x37\x8f\x21\xba\x90\x33\xe7\x22\x43\xc4\x2c\x97\xc2"
          "\x38\x38\x36\x99\x07\xdd\x97\x79\x51\x7b\x8e\x89\x4e\x4b\x1d\x0e"
          "\x54\x5a\x18\x9d\xb0\x0d\x7d\x07\xc2\x20\xe3\x12\x99\xba\x39\x6a"
          "\xd8\x46\xae\xbb\xc4\x71\xb2\xd7\xef\x4a\xbb\x6d\xdf\x51\xe9\x51"
          "\x1e\x00\x5f\x25\x54\xb3\x54\xbf\x84\x13\x06\xe3\x70\x77\x01\xab"
          "\x8f\xf5\x56\x90\x12\xc3\x56\xb3\x4b\xd7\x82\x5b\x96\x18\x1b\x5b"
          "\x4a\x2f\x22\x62\x19\x65\x20\xe6\xb2\xa4\x90\xab\x85\xea\x95\x4d"
          "\xfe\xbb\x9f\xb1\x41\xfa\x5f\x39\xf4\x6a\x88\x68\xd7\x35\x83\x91"
          "\xaa\x8c\x08\x7e\x9d\x34\x59\x47\x24\xa4\xe2\x0e\x38\x54\x6b\x3e"
          "\x12\x7c\x9e\xb5\xa2\x9f\x4a\xda\x5e\x28\xac\xc7\xf7\x48\x5c\x43"
          "\x6e\x54\xfa\x85\x3f\x95\x7d\x70\xa9\xa4\x28\x24\xab\x16\x19\x5a"
          "\xfc\xbf\x11\x4d\xf5\x69\x5e\x85\x0a\xaf\xa6\xb2\xc0\x66\x0b\x26"
          "\x98\x59\x21\xa3\xe3\xf7\x3a\x79\xe1\xdd\x0e\x45\x67\x31\xed\xe6"
          "\xa3\x02\x5c\x41\xc5\x45\x7a\x47\x94\x57\x71\x65\x36\x5b\x06\x8a"
          "\xb7\x06\x58\xf8\x5d\x12\x7c\x3d\xc8\x59\x7c\xdb\x36\xd4\xf2\xd7"
          "\xd0\x93\x2a\xd7\xed\x4b\x17\x17\x8b\x9b\xf1\x06\x7d\x9b\x1b\x6a";

        const unsigned char *p = pubkey_der;
        EVP_PKEY *pkey = d2i_PUBKEY(NULL, &p, (long)(sizeof(pubkey_der) - 1));
        if (pkey == NULL)
          return 1;

        EVP_MD_CTX *ctx = EVP_MD_CTX_new();
        if (ctx == NULL) {
          EVP_PKEY_free(pkey);
          return 1;
        }

        int ok =
          (EVP_DigestVerifyInit(ctx, NULL, EVP_sha1(), NULL, pkey) == 1) &&
          (EVP_DigestVerify(ctx,
                            signature, sizeof(signature) - 1,
                            corpus,    sizeof(corpus)    - 1) == 1);

        EVP_MD_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return ok ? 0 : 1;
    },
  )
  or do {
    print STDERR "wrong result: Failed to verify cryptographic SHA-1 support in OpenSSL.\n"
      . "  To enable SHA-1 for runtime purposes, see\n"
      . "    https://doc.zonemaster.net/latest/installation/zonemaster-engine.html\n"
      . "  To enable SHA-1 for package test purposes, see\n"
      . "    https://fedoraproject.org/wiki/SHA1SignaturesGuidance\n";
    exit 2;    # Mimic exit status of assert_lib
  };

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

    my $docker_make = <<'END_DOCKER';

docker-build:
	docker build --tag zonemaster/ldns:local --build-arg version=$(VERSION) .

docker-tag-version:
	docker tag zonemaster/ldns:local zonemaster/ldns:$(VERSION)

docker-tag-latest:
	docker tag zonemaster/ldns:local zonemaster/ldns:latest

END_DOCKER

    my $configure_flags_make = <<'END_CONFIGURE_FLAGS';

CONFIGURE_FLAGS += --disable-ldns-config --disable-dane

END_CONFIGURE_FLAGS

    my $openssl_make = <<END_OPENSSL_MAKE;

CONFIGURE_FLAGS += --with-ssl=$$opt_assets{openssl}{prefix}

END_OPENSSL_MAKE

    my $openssl_flags = <<END_OPENSSL_FLAGS;

CFLAGS += -I$$opt_assets{openssl}{inc}
LDFLAGS += -L$$opt_assets{openssl}{lib}

END_OPENSSL_FLAGS

    my $ed25519_make = <<'END_ED25519';

CONFIGURE_FLAGS += --enable-ed25519

END_ED25519

    my $no_ed25519_make = <<'END_NO_ED25519';

CONFIGURE_FLAGS += --disable-ed25519

END_NO_ED25519

    my $internal_ldns_make = <<'END_INTERNAL_LDNS';

CFLAGS += -fPIC
LDFROM += ldns/.libs/libldns.a

config :: ldns/.libs/libldns.a

ldns/.libs/libldns.a: ldns/configure
	cd ldns ;\
	./configure CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" $(CONFIGURE_FLAGS) ;\
	make lib

ldns/configure: ldns/Changelog
	cd ldns ; libtoolize -ci
	cd ldns ; autoreconf -fi

ldns/Changelog:
	git submodule init
	git submodule sync
	git submodule update

END_INTERNAL_LDNS

    my $postamble = '';

    $postamble .= $contributors_make;
    $postamble .= $docker_make;
    if ( $opt_internal_ldns ) {
        $postamble .= $configure_flags_make;
        $postamble .= $openssl_make    if $$opt_assets{openssl}{prefix};
        $postamble .= $ed25519_make    if $opt_ed25519;
        $postamble .= $no_ed25519_make if !$opt_ed25519;
        $postamble .= $openssl_flags   if ( $$opt_assets{openssl}{inc} or $$opt_assets{openssl}{lib} );
        $postamble .= $internal_ldns_make;
    }

    return $postamble;
} ## end sub MY::postamble

sub MY::test_via_harness {
    local $_ = shift()->MM::test_via_harness( @_ );
    s/\bPERL_DL_NONLAZY=1 +//g;
    return $_;
}

sub MY::test_via_script {
    local $_ = shift()->MM::test_via_script( @_ );
    s/\bPERL_DL_NON_LAZY=1 +//g;
    return $_;
}

WriteAll;
