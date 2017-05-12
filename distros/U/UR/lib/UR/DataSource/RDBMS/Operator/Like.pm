use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::Like;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = "$expr_sql like ?";
    if ($escape) {
        $sql .= " escape $escape";
    }
    return ($sql, $val);
}

1;
