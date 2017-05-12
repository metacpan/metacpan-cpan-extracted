use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::Between;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = "$expr_sql between ? and ?";
    return ($sql, @$val);
}

1;
