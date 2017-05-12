use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::False;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = qq(( $expr_sql IS NULL or $expr_sql = 0 ));

    return ($sql);
}

1;
