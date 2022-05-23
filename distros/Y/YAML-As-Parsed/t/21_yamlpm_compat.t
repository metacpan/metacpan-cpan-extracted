use strict;
use warnings;
use lib 't/lib/';
use Test::More 0.88;
use TestBridge;
use File::Spec::Functions 'catfile';
use File::Temp 0.19; # newdir

#--------------------------------------------------------------------------#
# This file test that the YAML.pm compatible Dump/Load/DumpFile/LoadFile
# work as documented
#--------------------------------------------------------------------------#

use YAML::As::Parsed;

{
    my $scalar = 'this is a string';
    my $arrayref = [ 1 .. 5 ];
    my $hashref = { alpha => 'beta', gamma => 'delta' };

    my $yamldump = YAML::As::Parsed::Dump( $scalar, $arrayref, $hashref );
    my @yamldocsloaded = YAML::As::Parsed::Load($yamldump);
    cmp_deeply(
        [ @yamldocsloaded ],
        [ $scalar, $arrayref, $hashref ],
        "Functional interface: Dump to Load roundtrip works as expected"
    );
}

{
    my $scalar = 'this is a string';
    my $arrayref = [ 1 .. 5 ];
    my $hashref = { alpha => 'beta', gamma => 'delta' };

    my $tempdir = File::Temp->newdir("YTXXXXXX", TMPDIR => 1 );
    my $filename = catfile($tempdir, 'compat');

    my $rv = YAML::As::Parsed::DumpFile(
        $filename, $scalar, $arrayref, $hashref);
    ok($rv, "DumpFile returned true value");

    my @yamldocsloaded = YAML::As::Parsed::LoadFile($filename);
    cmp_deeply(
        [ @yamldocsloaded ],
        [ $scalar, $arrayref, $hashref ],
        "Functional interface: DumpFile to LoadFile roundtrip works as expected"
    );
}

{
    my $str = "This is not real YAML";
    my @yamldocsloaded;
    eval { @yamldocsloaded = YAML::As::Parsed::Load("$str\n"); };
    error_like(
        qr/YAML::As::Parsed failed to classify line '$str'/,
        "Correctly failed to load non-YAML string"
    );
}

done_testing;
