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

my $opt_ed25519        = 1;
my $opt_idn            = 1;
my $opt_internal_ldns  = 1;
my $opt_debug          = 0;
my $opt_assets         = {
    openssl => {
        prefix => "",
        inc    => "",
        lib    => ""
    },
    ldns    => {
        inc    => "",
        lib    => ""
    },
    libidn => {
        inc    => "",
        lib    => ""
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

perl_version '5.026000'; # Perl v5.26.0 or higher is required for installation.

configure_requires 'Devel::CheckLib'         => 0;
configure_requires 'ExtUtils::PkgConfig'     => 0;
configure_requires 'Module::Install'         => 1.19;
configure_requires 'Module::Install::XSUtil' => 0;
#
test_requires      'JSON::PP'                => 0;
test_requires      'MIME::Base32'            => 0;
test_requires      'Test::Fatal'             => 0;
test_requires      'Test::Differences'       => 0;
test_requires      'Test::More'              => 1.302015;
test_requires      'Test::NoWarnings'        => 0;

use_ppport 3.19;
cc_include_paths 'include';
cc_src_paths 'src';


my %assert_lib_args = (
    openssl => {},
    libidn  => {},
    ldns    => {}
);

sub custom_assets
{
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
    }
    else {
        my %pkg_info = eval { ExtUtils::PkgConfig->find($pcname); };
        if ($@) {
            warn "$@\n";
            say "Guessing LDFLAGS for $name: -l${lib}";
            cc_libs $lib;
        }
        else {
            if ((my $cflags = $pkg_info{cflags}) ne '') {
                say "Adding CFLAGS for $name using pkg-config: $cflags";
                cc_include_paths $cflags;
            }
            if ((my $libs = $pkg_info{libs}) ne '') {
                say "Adding LDFLAGS for $name using pkg-config: $libs";
                cc_libs $libs;
            }
        }
    }
}

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
            debug    => $opt_debug,
            lib      => 'ldns',
            header   => 'ldns/ldns.h',
            %{ $assert_lib_args{ldns} },
            ccflags  => '-DUSE_ED25519',
            function => 'if(LDNS_ED25519) return 0; else return 1;'
        );
    }

    # NSID feature requires LDNS version >= 1.8.2
    $ldns_has_nsid = check_lib(
        debug    => $opt_debug,
        lib      => 'ldns',
        header   => 'ldns/util.h',
        %{ $assert_lib_args{ldns} },
        function => 'if ( LDNS_REVISION >= ((1<<16)|(8<<8)|(2)) ) return 0; else return 1;'
    );
}

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
        debug    => $opt_debug,
        lib    => 'idn2',
        header => 'idn2.h',
        %{ $assert_lib_args{libidn} },
        function => 'return IDN2_OK;'
    );
    cc_define '-DWE_CAN_HAZ_IDN';
}
else {
    print "Feature idn disabled\n";
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
        $postamble .= $openssl_make if $$opt_assets{openssl}{prefix};
        $postamble .= $ed25519_make if $opt_ed25519;
        $postamble .= $no_ed25519_make if !$opt_ed25519;
        $postamble .= $openssl_flags if ( $$opt_assets{openssl}{inc} or $$opt_assets{openssl}{lib} );
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
