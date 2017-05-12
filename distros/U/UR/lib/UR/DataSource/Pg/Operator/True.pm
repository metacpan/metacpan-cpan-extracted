use strict;
use warnings;

package UR::DataSource::Pg::Operator::True;

sub generate_sql_for {
    my($class, $expr_sql, $val, $escape) = @_;

    my $sql = qq(( $expr_sql IS NOT NULL and ${expr_sql}::text != '0' and ${expr_sql}::text != ''  ));

    return ($sql);
}

1;
