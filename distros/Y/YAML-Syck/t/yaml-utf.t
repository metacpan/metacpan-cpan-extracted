use strict;
use warnings;

use utf8;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More tests => 3;
use YAML::Syck;

{
    # There was bug that caused Syck no to quote unprintables
    # when a wide character was present.

    my $dump;
    local $YAML::Syck::ImplicitUnicode = 1;

    my $thing = "♥\000";
    $dump = YAML::Syck::Dump($thing);
    is( $dump, '--- "♥\0"' . "\n" );
}

{
    my $dump;
    local $YAML::Syck::ImplicitUnicode = 1;

    my $thing = "♥";
    $dump = YAML::Syck::Dump($thing);
    is( $dump, '--- ♥' . "\n" );
}

{
    my $dump;

    my $thing = "\000";
    $dump = YAML::Syck::Dump($thing);
    is( $dump, '--- "\0"' . "\n" );
}
