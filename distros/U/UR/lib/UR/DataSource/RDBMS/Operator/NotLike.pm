use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::NotLike;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = "$expr_sql not like ?";
    if ($escape) {
        $sql .= " escape $escape";
    }
    return ($sql, $val);
}

1;
