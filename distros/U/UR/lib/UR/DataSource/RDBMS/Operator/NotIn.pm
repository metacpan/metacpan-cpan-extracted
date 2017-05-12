use strict;
use warnings;

package UR::DataSource::RDBMS::Operator::NotIn;

use base 'UR::DataSource::RDBMS::Operator::In';

sub _negation_clause { ' not' };  # note the leading space

1;
