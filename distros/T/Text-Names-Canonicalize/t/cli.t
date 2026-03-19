use strict;
use warnings;
use Test::Most;
use File::Spec;

my $cli = File::Spec->catfile(qw(bin text-names-canonicalize));

ok(-f $cli, "CLI script exists");

my $cmd;

if ($^O eq 'MSWin32') {
    # Windows must invoke Perl explicitly
    $cmd = qq{"$^X" "$cli" --locale fr_FR "Jean d'Ormesson"};
} else {
    # Unix-like systems can run the script directly
    $cmd = qq{"$cli" --locale fr_FR "Jean d'Ormesson"};
}

my $out = qx{$cmd};
my $exit = $? >> 8;

is($exit, 0, "CLI exited cleanly");

chomp $out;
is($out, "jean d'ormesson", "CLI canonicalized correctly");

done_testing;

