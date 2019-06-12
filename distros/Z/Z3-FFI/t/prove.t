use Test::More;

use strict;
use warnings;
use Data::Dumper;
use lib './';
use t::lib::helpers;

use_ok("Z3::FFI");

my $ctx = mk_context();
my $solver = mk_solver($ctx);

my $U_name = Z3::FFI::mk_string_symbol($ctx, "U");
check_type($U_name, "Z3_symbol", "U name correct type");
my $U = Z3::FFI::mk_uninterpreted_sort($ctx, $U_name);
check_type($U, "Z3_sort", "U correct type");

my $g_name = Z3::FFI::mk_string_symbol($ctx, "g");
check_type($g_name, "Z3_symbol", "g name correct type");
my $g = Z3::FFI::mk_func_decl($ctx, $g_name, 1, [$U], $U);
check_type($g, "Z3_func_decl", "g function correct type");

# create our x and y
my $x_name = Z3::FFI::mk_string_symbol($ctx, "x");
my $y_name = Z3::FFI::mk_string_symbol($ctx, "y");
check_type($x_name, "Z3_symbol", "x name correct type");
check_type($y_name, "Z3_symbol", "y name correct type");
my $x = Z3::FFI::mk_const($ctx, $x_name, $U);
my $y = Z3::FFI::mk_const($ctx, $y_name, $U);
check_type($x, "Z3_ast", "x correct type");
check_type($y, "Z3_ast", "y correct type");

# create g(x) and g(y)
my $gx = mk_unary_app($ctx, $g, $x);
my $gy = mk_unary_app($ctx, $g, $y);
my $ggx = mk_unary_app($ctx, $g, $gx);

# assert x == y
my $equal = Z3::FFI::mk_eq($ctx, $x, $y);
Z3::FFI::solver_assert($ctx, $solver, $equal);

# Create g(x) == g(y)
my $func_eq = Z3::FFI::mk_eq($ctx, $gx, $gy);

# prove it
prove($ctx, $solver, $func_eq, Z3::FFI::Z3_TRUE());

# try to assert that g(g(x)) == g(y), x == y
my $other_func = Z3::FFI::mk_eq($ctx, $ggx, $gy);
prove($ctx, $solver, $other_func, Z3::FFI::Z3_FALSE(), "double application", <<"EOF");
y -> U!val!0
x -> U!val!0
g -> {
  U!val!1 -> U!val!2
  else -> U!val!1
}
EOF

del_solver($ctx, $solver);
Z3::FFI::del_context($ctx);

done_testing;

1;
