
# This code was generated automatically. Consider re-generating this file
# if you are to make any changes.

package DB::Table::[% TABLE.moduleName %];

use strict;

use Carp qw(cluck);
use DB::Table;
our @ISA = (qw(DB::Table));

# This is the structure that represents the table.
our $tableData = [% DATA %]

sub open
{
    my $ref   = shift;
    my $class = ref($ref) || $ref;

    my $dbh = shift || confess ("Usage: $class->open(\$dbh)");
    return $class->SUPER::open($dbh, $tableData);
}

1;

