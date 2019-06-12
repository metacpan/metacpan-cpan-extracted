use Test::More;

use strict;
use warnings;
use Data::Dumper;
use lib './';
use t::lib::helpers;

use_ok("Z3::FFI");

my $config = Z3::FFI::mk_config();
check_type($config, "Z3_config", "Config comes back as correct type");
my $ctx = Z3::FFI::mk_context($config);
check_type($ctx, "Z3_context", "Context comes back as correct type");
Z3::FFI::del_config($config); # delete config, like the c example does

# model 1
my $x = mk_bool_var($ctx, "x");
my $y = mk_bool_var($ctx, "y");;
check_type($x, "Z3_ast", "Variable comes back as correct type");
check_type($y, "Z3_ast", "Variable comes back as correct type");

my $x_xor_y = Z3::FFI::mk_xor($ctx, $x, $y);

my $solver = mk_solver($ctx);

Z3::FFI::solver_assert($ctx, $solver, $x_xor_y);
check($ctx, $solver, Z3::FFI::Z3_L_TRUE(), "XOR Model", <<"EOM");
y -> false
x -> true
EOM
Z3::FFI::solver_dec_ref($ctx, $solver);
Z3::FFI::del_context($ctx);
undef $solver;
undef $ctx;

$config = Z3::FFI::mk_config();
$ctx = Z3::FFI::mk_context($config);

# Model two, finds a solution to
# V < W + 1
# V > 2
# V != W

my $v = mk_int_var($ctx, "v");
my $w = mk_int_var($ctx, "w");
my $one = mk_int($ctx, 1);
my $two = mk_int($ctx, 2);

check_type($v, "Z3_ast", "V is correct type");
check_type($w, "Z3_ast", "W is correct type");
check_type($one, "Z3_ast", "1 is correct type");
check_type($two, "Z3_ast", "2 is correct type");

my $w_plus_one = Z3::FFI::mk_add($ctx, 2, [$w, $one]);
check_type($w_plus_one, "Z3_ast", "W+1 is correct type");

my $constraint_1 = Z3::FFI::mk_lt($ctx, $v, $w_plus_one);
my $constraint_2 = Z3::FFI::mk_gt($ctx, $v, $two);
check_type($constraint_1, "Z3_ast", "Constraint 1 is correct type");
check_type($constraint_2, "Z3_ast", "Constraint 2 is correct type");

$solver = mk_solver($ctx);

Z3::FFI::solver_assert($ctx, $solver, $constraint_1);
Z3::FFI::solver_assert($ctx, $solver, $constraint_2);

check($ctx, $solver, Z3::FFI::Z3_L_TRUE(), "Equation model simple", <<"EOM");
v -> 3
w -> 3
EOM

my $equal = Z3::FFI::mk_eq($ctx, $v, $w); # v == w
check_type($equal, "Z3_ast", "Equal is correct type");
my $not_equal = Z3::FFI::mk_not($ctx, $equal); # !(v == w)
check_type($not_equal, "Z3_ast", "Not equal is correct type");

Z3::FFI::solver_assert($ctx, $solver, $not_equal);
pass("Solver assert added new condition");

check($ctx, $solver, Z3::FFI::Z3_L_TRUE(), "Equation more complex", <<"EOM");
w -> 4
v -> 3
EOM

# clean up the solver
Z3::FFI::solver_dec_ref($ctx, $solver);
undef $solver;

Z3::FFI::del_context($ctx);

done_testing;

1;
