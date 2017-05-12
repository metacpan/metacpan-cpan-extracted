use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::Equals;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql;
    my @sql_params;
    if (UR::DataSource::RDBMS->_value_is_null($val)) {
        $sql = "$expr_sql IS NULL";
    } else {
        $sql = "$expr_sql = ?";
        @sql_params = ($val);
    }

    return ($sql, @sql_params);
}

1;
