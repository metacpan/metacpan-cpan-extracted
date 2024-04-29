#! perl -w
use strict;

use File::Path;
use File::Spec::Functions;
use File::Temp qw( tempdir );

my $temp_dir = tempdir(CLEANUP => 1);
my $lib = catdir($temp_dir, 'Factory');
mkpath("$lib/JSON", $ENV{TEST_VERBOSE});
mkpath("$lib/Cpanel/JSON", $ENV{TEST_VERBOSE});

require lib;
lib->import($lib);

# Do not import, it will find installed JSON::PP/XS :(
use Test::Smoke::Util::LoadAJSON ();

# Preload modules before we mess with @INC
require Data::Dumper;  # Test::More::explain()
require Scalar::Util;  # Test::More::isa_ok()
require Carp;          # our JSON.pm might need it;
use Test::More;
use Test::NoWarnings ();

my %code = (
    'PP' => <<'    EOPP',
package JSON::PP;
    EOPP
    'XS' => <<'    EOXS',
package JSON::XS;
    EOXS
    'Cpanel' => <<'    EOCP',
package Cpanel::JSON::XS;
    EOCP
    General => <<'    EOGEN',
sub new { my $c = shift; return bless {}, $c; }
sub encode_json { return __PACKAGE__ . "\::encode_json()"; }
sub decode_json { return __PACKAGE__ . "\::decode_json()"; }
1;
    EOGEN
);

{
    like(
        $INC{'Test/Smoke/Util/LoadAJSON.pm'},
        qr{LoadAJSON\.pm},
        "Loaded the correct JSON-factory"
    );
}

{
    my $type = 'PP';
    my $fname = "$lib/JSON/$type.pm";
    note("Check we can find JSON::$type");

    # Write the contents of the mock module
    open my $pkg, '>', $fname or die "Cannot create($fname): $!";
    print $pkg $code{$type};
    print $pkg $code{General};
    close $pkg;
    note(sprintf("Written JSON::%s %sOk", $type, -f $fname ? "" : "NOT "));

    delete($INC{'JSON.pm'}); reset 'JSON';
    local @INC = ($lib);
    Test::Smoke::Util::LoadAJSON->import();
    is(JSON(), 'JSON::PP', "base class is JSON::PP");

    my $obj = Test::Smoke::Util::LoadAJSON->new;
    isa_ok($obj, 'JSON::PP');


    is(encode_json(), 'JSON::PP::encode_json()', "JSON::PP::encode_json()");
    is(decode_json(), 'JSON::PP::decode_json()', "JSON::PP::decode_json()");
    is($obj->encode_json(), 'JSON::PP::encode_json()', "JSON::PP->encode_json()");
    is($obj->decode_json(), 'JSON::PP::decode_json()', "JSON::PP->decode_json()");

    # Clean up stuff for the next test.
    delete($INC{'JSON/PP.pm'});
    1 while unlink $fname;
}

{
# This test will spew 'Subroutine main::encode_json redefined at Exporter.pm'
# I don't know how to stop it from doing that.
    local $SIG{__WARN__} = sub {
        if ($_[0] !~ /^Subroutine main::(?:en|de)code_json redefined at/) {
            warn @_;
        }
    };
    my $type = 'XS';
    my $fname = "$lib/JSON/$type.pm";
    note("Check we can find JSON::$type");
    open my $pkg, '>', $fname or die "Cannot create($fname): $!";
    print $pkg $code{$type};
    print $pkg $code{General};
    close $pkg;
    note(sprintf("Written JSON::%s %sOk", $type, -f $fname ? "" : "NOT "));

    delete($INC{'JSON.pm'});
    local @INC = ($lib);
    Test::Smoke::Util::LoadAJSON->import();
    is(JSON(), 'JSON::XS', "base class is JSON::XS");

    my $obj = Test::Smoke::Util::LoadAJSON->new;
    isa_ok($obj, 'JSON::XS');

    is(encode_json(), 'JSON::XS::encode_json()', "JSON::XS::encode_json()");
    is(decode_json(), 'JSON::XS::decode_json()', "JSON::XS::decode_json()");
    is($obj->encode_json(), 'JSON::XS::encode_json()', "JSON::XS->encode_json()");
    is($obj->decode_json(), 'JSON::XS::decode_json()', "JSON::XS->decode_json()");
    #
    # Clean up stuff for the next test.
    delete($INC{'JSON/XS.pm'});
    # 1 while unlink $fname; # Leave it, Cpanel::JSON::XS is preferred
}

{
# This test will spew 'Subroutine main::encode_json redefined at Exporter.pm'
# I don't know how to stop it from doing that.
    local $SIG{__WARN__} = sub {
        if ($_[0] !~ /^Subroutine main::(?:en|de)code_json redefined at/) {
            warn @_;
        }
    };
    my $type = 'Cpanel';
    my $fname = catfile($lib, $type, "JSON","XS.pm");
    note("Check we can find JSON::$type");
    open my $pkg, '>', $fname or die "Cannot create($fname): $!";
    print $pkg $code{$type};
    print $pkg $code{General};
    close $pkg;
    note(sprintf("Written JSON::%s %sOk", $type, -f $fname ? "" : "NOT "));

    delete($INC{'JSON/XS.pm'});
    local @INC = ($lib);
    Test::Smoke::Util::LoadAJSON->import();
    is(JSON(), 'Cpanel::JSON::XS', "base class is Cpanel::JSON::XS");

    my $obj = Test::Smoke::Util::LoadAJSON->new;
    isa_ok($obj, 'Cpanel::JSON::XS');

    is(encode_json(),       'Cpanel::JSON::XS::encode_json()', "Cpanel::JSON::XS::encode_json()");
    is(decode_json(),       'Cpanel::JSON::XS::decode_json()', "Cpanel::JSON::XS::decode_json()");
    is($obj->encode_json(), 'Cpanel::JSON::XS::encode_json()', "Cpanel::JSON::XS->encode_json()");
    is($obj->decode_json(), 'Cpanel::JSON::XS::decode_json()', "Cpanel::JSON::XS->decode_json()");
    #
    # Clean up stuff for the next test.
    delete($INC{'Cpanel/JSON/XS.pm'});
    # 1 while unlink $fname;
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
