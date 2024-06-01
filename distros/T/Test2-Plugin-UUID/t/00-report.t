use Test2::Tools::Basic;
use Test2::Util::Table qw/table/;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;

# Nothing in the tables in this file should result in a table wider than 80
# characters, so this is an optimization.
BEGIN { $ENV{TABLE_TERM_SIZE} = 80 }

diag "\nDIAGNOSTICS INFO IN CASE OF FAILURE:\n";
diag(join "\n", table(rows => [[ 'perl', $] ]]));
print STDERR "\n";

{
    my @mods = qw{
Atomic::Pipe
Data::UUID
Data::UUID::MT
Test2::API
Test2::V0
UUID
UUID::Tiny
    };

    my @rows;
    for my $mod (sort @mods) {
        my $installed = eval "require $mod; $mod->VERSION";
        push @rows => [$mod, $installed || "N/A"];
    }

    my @table = table(
        header => ['MODULE', 'VERSION'],
        rows   => \@rows,
    );

    diag(join "\n", @table);
}

pass('pass');
done_testing;
