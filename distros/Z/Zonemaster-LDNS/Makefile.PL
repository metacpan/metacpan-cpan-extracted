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
repository 'https://github.com/dotse/zonemaster-ldns';
bugtracker 'https://github.com/dotse/zonemaster-ldns/issues';

my $opt_randomize     = 0;
my $opt_idn           = 1;
my $opt_internal_ldns = 1;
GetOptions(
    'randomize!'     => \$opt_randomize,
    'idn!'           => \$opt_idn,
    'internal-ldns!' => \$opt_internal_ldns,
);

configure_requires 'Devel::CheckLib';
requires 'MIME::Base64';
test_requires 'JSON::PP';
test_requires 'Test::Fatal';

use_ppport 3.19;
cc_libs 'crypto';
cc_include_paths 'include';
cc_src_paths 'src';

if ( $opt_internal_ldns ) {
    cc_libs '-Lldns/lib';
    cc_include_paths 'ldns';
    print "Feature internal ldns enabled\n";
}
else {
    cc_libs 'ldns';
    print "Feature internal ldns disabled\n";
}

my %assert_args = (
    lib      => 'crypto',
    header   => 'openssl/crypto.h',
    function => 'if(SSLeay()) return 0; else return 1;'
);

cc_assert_lib %assert_args;

if ( $opt_idn ) {
    check_lib_or_exit(
        lib    => 'idn',
        header => 'idna.h',
        function =>
          'if(strcmp(IDNA_ACE_PREFIX,"xn--")==0) return 0; else return 1;'
    );
    cc_libs 'idn';
    cc_define '-DWE_CAN_HAZ_IDN';
    print "Feature idn enabled\n";
}
else {
    print "Feature idn disabled\n";
}

if ( $opt_randomize ) {
    cc_define '-DRANDOMIZE';
    print "Feature randomized capitalization enabled\n";
}
else {
    print "Feature randomized capitalization disabled\n";
}

sub MY::postamble {

    my $internal_ldns_make = <<'END_INTERNAL_LDNS';

LDFROM += ldns/.libs/libldns.a

config :: ldns/.libs/libldns.a

ldns/.libs/libldns.a: ldns/configure
	cd ldns ;\
	./configure CFLAGS=-fPIC --disable-ldns-config --disable-dane ;\
	make lib

ldns/configure:
	git submodule update --init
	cd ldns ; libtoolize -ci
	cd ldns ; autoreconf -fi

END_INTERNAL_LDNS

    my $contributors_make = <<'END_CONTRIBUTORS';

CONTRIBUTORS.txt:
	@( \
	echo "This module is based on the ldns library from NLnet Labs <https://www.nlnetlabs.nl/projects/ldns/>" ; \
    echo ; \
	echo "Contributors to this module:" ; \
	git shortlog -sne | cut -b8- \
	) >| CONTRIBUTORS.txt

END_CONTRIBUTORS

    my $postamble = '';

    $postamble .= $contributors_make;
    $postamble .= $internal_ldns_make if $opt_internal_ldns;

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
