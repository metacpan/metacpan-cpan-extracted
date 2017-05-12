use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::NotEquals;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql;
    my @sql_params;
    if (UR::DataSource::RDBMS->_value_is_null($val)) {
        $sql = "$expr_sql IS NOT NULL";
    } else {
        $sql = sprintf("( %s != ? or %s is null)", $expr_sql, $expr_sql);
        @sql_params = ($val);
    }

    return ($sql, @sql_params);
}

1;
