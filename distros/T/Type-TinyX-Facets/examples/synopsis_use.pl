use My::Types -types;
use Type::Params qw[ validate ];

validate( [ 5 ], MinMax[min => 2] );            # passes
validate( [ 5 ], MinMax[min => 2, max => 6] );  # passes

validate( [ 5 ], Bounds[min => 2] );            # passes
validate( [ 5 ], Bounds[min => 2, max => 6] );  # passes
validate( [ 5 ], Bounds[min => 5, max => 2] );  # fails to construct as min > max

validate( [ 0 ], Positive[positive => 1] );     # fails!
validate( [ 1 ], Positive[positive => 1] );     # passes

