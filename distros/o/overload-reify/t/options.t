#!perl

# test allowed options

use Test::Lib;
use Test2::Bundle::Extended;


{ package C1;

  use base qw[ Parent ];

  # do everything
  use overload::reify;
}

# make sure we set things up correctly
subtest "inherited methods" => sub {
    ok( C1->can( $_ ), $_ ) for 'plus_equals';
    ok( C1->can( $_ ), $_ ) for 'minus_equals';
};

subtest "no options" => sub {
    ok( C1->can( $_ ), $_ ) for 'operator_add_assign';
    ok( C1->can( $_ ), $_ ) for 'operator_subtract_assign';
};

{ package C2;

  use base qw[ Parent ];

  # do nothing
  use overload::reify -not => ':all';
}

subtest "-not => ':all'" => sub {
    ok( !C2->can( $_ ), $_ ) for 'operator_add_assign';
    ok( !C2->can( $_ ), $_ ) for 'operator_subtract_assign';
};

{ package C2_1;

  use base qw[ Parent ];

  # do nothing
  use overload::reify -not => ':all', -not => '=';
}

subtest "-not => ':all', -not => '-='" => sub {
    ok( !C2_1->can( $_ ), $_ ) for 'operator_add_assign';
    ok( !C2_1->can( $_ ), $_ ) for 'operator_subtract_assign';
};

{ package C3;

  use base qw[ Parent ];

  use overload::reify +{ -prefix => 'smooth_' };
}

subtest "-prefix" => sub {
    ok( C3->can( $_ ), $_ ) for 'smooth_add_assign';
    ok( C3->can( $_ ), $_ ) for 'smooth_subtract_assign';
};

{ package C4;

  use base qw[ Parent ];

  use overload::reify +{ -methods => 0 };
}

subtest "-methods => 0" => sub {
    ok( !C4->can( $_ ), $_ ) for 'operator_add_assign';
    ok( C4->can( $_ ), $_ ) for 'operator_subtract_assign';
};

{ package C5;
  use base qw[ Parent ];
}
use overload::reify +{ -into => 'C5' };


subtest "-into" => sub {
    ok( C5->can( $_ ), $_ ) for 'operator_add_assign';
    ok( C5->can( $_ ), $_ ) for 'operator_subtract_assign';
};


done_testing;
