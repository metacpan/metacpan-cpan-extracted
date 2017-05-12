use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::NotBetween;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = "$expr_sql not between ? and ?";
    return ($sql, @$val);
}

1;
