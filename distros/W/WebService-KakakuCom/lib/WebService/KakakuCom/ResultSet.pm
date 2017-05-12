package WebService::KakakuCom::ResultSet;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

use overload '@{}' => 'as_array', fallback => 1;

__PACKAGE__->mk_accessors(qw/NumOfResult results pager/);

sub as_array {
    shift->results;
}

1;
