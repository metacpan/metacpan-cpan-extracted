use strict;
use warnings;

package UR::DataSource::Pg::Operator::False;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = qq(( $expr_sql IS NULL or ${expr_sql}::text = '0' or ${expr_sql}::text = ''  ));

    return ($sql);
}

1;
