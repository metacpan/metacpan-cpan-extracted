package WebService::SimpleAPI::Wikipedia::ResultSet;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

use overload '@{}' => 'as_array', fallback => 1;

__PACKAGE__->mk_accessors(qw/nums results/);

sub as_array {
    shift->results;
}

1;
