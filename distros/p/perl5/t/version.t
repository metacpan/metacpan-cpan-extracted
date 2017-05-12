my $t; use lib ($t = -e 't' ? 't' : 'test');
use lib "$t/lib";

use Test::More tests => 31;

test_usage1($_) for split "\n", <<'';
use perl5 v10;
use perl5 10;
use perl5 '10';
use perl5-10;
use perl5 v10.0;
use perl5 10.0;
use perl5 '10.0';
use perl5-10.0;
use perl5 v10 -xyzzy;
use perl5 10 -xyzzy;
use perl5 '10' => -xyzzy;
use perl5-10 => -xyzzy;
use perl5 v10.0 -xyzzy;
use perl5 10.0 -xyzzy;
use perl5 '10.0' => -xyzzy;
use perl5-10.0 => -xyzzy;
use perl5;
use perl5-xyzzy;

sub test_usage1 {
    my $usage = shift;
    eval $usage;
    my $error = $@;
    diag($@) if $@;
    ok not($@), "Usage: '$usage' is ok";
}

test_usage2($_) for split "\n", <<'';
use perl5 v90.0;
use perl5 90.0;
use perl5 '90.0';
use perl5-90.0;
use perl5 v90.0 -xyzzy;
use perl5 90.0 -xyzzy;
use perl5 90.0, -xyzzy;
use perl5 '90.0',-xyzzy;
use perl5 '90.0' => -xyzzy;
use perl5-90.0 => -xyzzy;
use perl5-90.0,-xyzzy;

sub test_usage2 {
    my $usage = shift;
    eval $usage;
    my $error = $@;
    unless ($error) {
        fail "'$usage' failed to fail";
        return;
    }
    like $error, qr/\QPerl v5.90.0 required--this is only v5.\E/,
        "'$usage' usage failed appropriately";
}

{
    my $usage = "use perl5 9;";
    eval $usage;
    like $@, qr/^\Qperl5 version 9 required--this is only version\E/,
        "'$usage' usage failed appropriately";
}

{
    my $usage = "use subclass 8 ();";
    eval $usage;
    like $@, qr/^\Qsubclass version 8 required--this is only version 1.23\E/,
        "'$usage' usage failed appropriately";
}


