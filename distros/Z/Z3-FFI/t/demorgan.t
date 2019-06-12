use Test::More;

use strict;
use warnings;

use lib '.';
use t::lib::helpers;

use_ok("Z3::FFI");

my $config = Z3::FFI::mk_config();
check_type($config, "Z3_config", "Config comes back as correct type");
my $ctx = Z3::FFI::mk_context($config);
check_type($ctx, "Z3_context", "Context comes back as correct type");
Z3::FFI::del_config($config); # delete config, like the c example does

my $bool_sort = Z3::FFI::mk_bool_sort($ctx);
check_type($bool_sort, "Z3_sort", "Bool sort comes back as correct type");

my $x_sym = Z3::FFI::mk_int_symbol($ctx, 0);
my $y_sym = Z3::FFI::mk_int_symbol($ctx, 1);
check_type($x_sym, "Z3_symbol", "Symbol comes back as correct type");
check_type($y_sym, "Z3_symbol", "Symbol comes back as correct type");

my $x = Z3::FFI::mk_const($ctx, $x_sym, $bool_sort);
my $y = Z3::FFI::mk_const($ctx, $y_sym, $bool_sort);
check_type($x, "Z3_ast", "X comes back as correct type");
check_type($y, "Z3_ast", "Y comes back as correct type");

my ($not_x, $not_y) = map {Z3::FFI::mk_not($ctx, $_)} $x, $y;
check_type($not_x, "Z3_ast", "Not_X comes back as correct type");
check_type($not_y, "Z3_ast", "Not_Y comes back as correct type");

my $x_and_y = Z3::FFI::mk_and($ctx, 2, [$x, $y]);
check_type($x_and_y, "Z3_ast", "X && Y is correct type");

my $inverse_xy = Z3::FFI::mk_not($ctx, $x_and_y);
check_type($inverse_xy, "Z3_ast", "inverse x&&y is correct type");

my $or_not = Z3::FFI::mk_or($ctx, 2, [$not_x, $not_y]);
check_type($or_not, "Z3_ast", "Or_not is correct type");

my $conjecture = Z3::FFI::mk_iff($ctx, $inverse_xy, $or_not);
my $negative   = Z3::FFI::mk_not($ctx, $conjecture);
check_type($conjecture, "Z3_ast", "Conjecture is correct type");
check_type($negative,   "Z3_ast", "Negative is correct type");

my $solver = Z3::FFI::mk_solver($ctx);
check_type($solver, "Z3_solver", "Solver is correct type");

Z3::FFI::solver_assert($ctx, $solver, $negative);
my $solution = Z3::FFI::solver_check($ctx, $solver);

if ($solution == Z3::FFI::Z3_L_FALSE()) {
    pass("Demorgan's law is valid")
} elsif ($solution == Z3::FFI::Z3_L_UNDEF()) {
    fail("Got indeterminate value from Demorgan's Law")
} elsif ($solution == Z3::FFI::Z3_L_TRUE()) {
    fail("Demorgan's law is invalid.  Please restart universe and try again");
}

Z3::FFI::solver_dec_ref($ctx, $solver);
Z3::FFI::del_context($ctx);

done_testing;

1;
