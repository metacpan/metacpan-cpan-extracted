package t::lib::helpers;
use warnings;
use strict;


use Test::More;
use warnings;

use Exporter;
use namespace::autoclean;
use Package::Stash;

sub import {
    our @EXPORT=Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
    goto \&Exporter::import;
}

sub check_type {
    my ($input, $type, $message) = @_;
    is(ref($input), "Z3::FFI::Types::".$type, $message);
}

sub error_handler {
    my ($ctx, $err) = @_;
    fail("Error code: $err");
    exit(1);
}

sub ignore_error_handler {
    my ($ctx, $err) = @_;
    diag("Ignored error code: $err");
}

sub mk_context_custom {
    my ($cfg, $err_handle) = @_;

    Z3::FFI::set_param_value($cfg, "model", "true");
    my $ctx = Z3::FFI::mk_context($cfg);
    check_type($ctx, "Z3_context", "mk_context_custom creates context");
    Z3::FFI::set_error_handler($ctx, $err_handle);

    return $ctx;
}

sub del_solver {
    my ($ctx, $solver) = @_;
    Z3::FFI::solver_dec_ref($ctx, $solver);
    pass("Deleted solver");
}

sub mk_context {
    my $cfg = Z3::FFI::mk_config();
    check_type($cfg, "Z3_config", "mk_context Config works");
    my $ctx = mk_context_custom($cfg, \&error_handler);
    Z3::FFI::del_config($cfg);

    return $ctx;
}

sub mk_proof_context {
    my $cfg = Z3::FFI::mk_config();
    check_type($cfg, "Z3_config", "mk_proof_context config works");
    Z3::FFI::set_param_value($cfg, "proof", "true");
    my $ctx = mk_custom_context($cfg, sub {
        die "Throw error in perl"; # TODO what?
    });
    Z3::FFI::del_config($cfg);
    return $ctx;
}

sub mk_solver {
  my ($ctx) = @_;
  my $solver = Z3::FFI::mk_solver($ctx);
  Z3::FFI::solver_inc_ref($ctx, $solver);
  check_type($solver, "Z3_solver", "Solver is correct type");
  return $solver;
}

sub mk_var {
    my ($ctx, $name, $sort) = @_;

    my $sym = Z3::FFI::mk_string_symbol($ctx, $name);
    check_type($sym, "Z3_symbol", "Symbol for $name");
    my $ast = Z3::FFI::mk_const($ctx, $sym, $sort);
    check_type($ast, "Z3_ast", "AST for $name");
    return $ast;    check_type($ctx, "Z3_context")
}

sub mk_bool_var {
    my ($ctx, $name) = @_;

    my $ty = Z3::FFI::mk_bool_sort($ctx);
    check_type($ty, "Z3_sort", "Bool sort for $name");
    my $var = mk_var($ctx, $name, $ty);
    check_type($var, "Z3_ast", "Bool var for $name");
    return $var;
}

sub mk_int_var {
    my ($ctx, $name) = @_;

    my $ty = Z3::FFI::mk_int_sort($ctx);
    check_type($ty, "Z3_sort", "Int sort for $name");
    my $var = mk_var($ctx, $name, $ty);
    check_type($var, "Z3_ast", "Int var for $name");
    return $var;
}

sub mk_int {
    my ($ctx, $value) = @_;
    my $ty = Z3::FFI::mk_int_sort($ctx);
    check_type($ty, "Z3_sort", "Int sort for int value");
    my $val = Z3::FFI::mk_int($ctx, $value, $ty);
    check_type($val, "Z3_ast", "Int value for int value");
    return $val;
}

sub mk_real_var {
    my ($ctx, $name) = @_;

    my $ty = Z3::FFI::mk_real_sort($ctx);
    check_type($ty, "Z3_sort", "Real sort for $name");
    my $var = mk_var($ctx, $name, $ty);
    check_type($var, "Z3_ast", "Real var for $name");
    return $var;
}

# create unary function application (f x)
sub mk_unary_app {
    my ($ctx, $func, $x) = @_;

    my $app = Z3::FFI::mk_app($ctx, $func, 1, [$x]);
    check_type($app, "Z3_ast", "Function application works");
    return $app;
}

# create unary function application (f x)
sub mk_binary_app {
    my ($ctx, $func, $x, $y) = @_;

    my $app = Z3::FFI::mk_app($ctx, $func, 2, [$x, $y]);
    check_type($app, "Z3_ast", "Function binary application works");
    return $app;
}

sub check {
    my ($ctx, $solver, $exp_result, $model_name, $model_test) = @_;

    my $result = Z3::FFI::solver_check($ctx, $solver);
    if ($result == Z3::FFI::Z3_L_FALSE()) {
        pass("Unable to satisfy model, $model_name");
    } elsif ($result == Z3::FFI::Z3_L_UNDEF()) {
        pass("Potential model found, $model_name");
    } elsif ($result == Z3::FFI::Z3_L_TRUE()) {
        pass("Model found, $model_name");
    } else {
        fail("Unknown value from solver_check, $model_name, ".$result);
        exit(-1); # Bail out entirely, something is really wrong.
    }

    is($result, $exp_result, "Model result matches expected");
    
    if ($exp_result != Z3::FFI::Z3_L_FALSE()) {
        my $model = Z3::FFI::solver_get_model($ctx, $solver);
        check_type($model, "Z3_model", "Model comes back successfully");
        Z3::FFI::model_inc_ref($ctx, $model);

        my $model_string = Z3::FFI::model_to_string($ctx, $model);
        is($model_string, $model_test, "Model for $model_name matches");
        Z3::FFI::model_dec_ref($ctx, $model);
    } else {
        pass("No model to attempt to display");
    }
}

sub prove {
    my ($ctx, $solver, $formula, $is_valid, $model_name, $model_test) = @_;

    # Save current context
    Z3::FFI::solver_push($ctx, $solver);
    pass("Able to save context with a push");

    my $not_f = Z3::FFI::mk_not($ctx, $formula);
    check_type($not_f, "Z3_ast", "Negation of formula made");

    Z3::FFI::solver_assert($ctx, $solver, $not_f); # assert not f

    my $result = Z3::FFI::solver_check($ctx, $solver);

    if ($result == Z3::FFI::Z3_L_FALSE()) {
        if (!$is_valid) {
            fail("F was proven.");
            die "Proved the wrong thing, bailing";
        } else {
            pass("F was not proven");
        }
    } elsif ($result == Z3::FFI::Z3_L_UNDEF()) {
        pass("Failed to disprove or prove F");
        my $model = Z3::FFI::solver_get_model($ctx, $solver);
        check_type($model, "Z3_model", "Produced model from solver");
        Z3::FFI::model_inc_ref($ctx, $model);
        my $model_string = Z3::FFI::model_to_string($ctx, $model);
        is($model_string, $model_test, "$model_name potential proof");
        Z3::FFI::model_dec_ref($ctx, $model);
    } elsif ($result == Z3::FFI::Z3_L_TRUE()) {
        pass("Failed to disprove or prove F");
        my $model = Z3::FFI::solver_get_model($ctx, $solver);
        check_type($model, "Z3_model", "Produced model from solver");
        Z3::FFI::model_inc_ref($ctx, $model);
        my $model_string = Z3::FFI::model_to_string($ctx, $model);
        is($model_string, $model_test, "$model_name proof");
        Z3::FFI::model_dec_ref($ctx, $model);
    } else {
        fail("Got unknown result $result for solver check");
    }

    Z3::FFI::solver_pop($ctx, $solver, 1);
}

sub assert_injective_axium {
    my ($ctx, $solver, $func, $i, $name, $pattern_test) = @_;

    my $sz = Z3::FFI::get_domain_size($ctx, $func);
    if ($i > $sz) {
        fail("Failed to create inj axiom");
        exit(1);
    }

    my $finv_domain = Z3::FFI::get_range($ctx, $func);
    my $finv_range  = Z3::FFI::get_domain($ctx, $func, $i);
    check_type($finv_domain, "Z3_sort", "F-inv domain is correct type");
    check_type($finv_range, "Z3_sort", "F-inv range is correct type");

    my $finv = Z3::FFI::mk_fresh_func_decl($ctx, "inv", 1, \$finv_domain, $finv_range);
    check_type($finv, "Z3_func_decl", "Inverse function is correct");

    my (@types, @names, @xs);

    for my $j (0..$sz) {
        my $type = Z3::FFI::get_domain($ctx, $func, $j);
        check_type($type, "Z3_sort", "Type was correct type");
        my $name = Z3::FFI::mk_int_symbol($ctx, $j);
        check_type($name, "Z3_symbol", "Name is correct type");
        my $xs   = Z3::FFI::mk_bound($ctx, $j, $type);
        check_type($xs, "Z3_ast", "XS was correct type");

        push @types, $type;
        push @names, $name;
        push @xs, $xs;
    }

    my $x_i = $xs[$i];

    my $fxs = Z3::FFI::mk_app($ctx, $func, $sz, \@xs);
    check_type($fxs, "Z3_ast", "fxs is correct type");

    my $finv_fxs = mk_unary_app($ctx, $finv, $fxs);
    check_type($finv_fxs, "Z3_ast", "finv_fxs is correct type");

    my $equal = Z3::FFI::mk_eq($ctx, $finv_fxs, $x_i);
    check_type($equal, "Z3_ast", "equal is correct type");

    my $pattern = Z3::FFI::mk_pattern($ctx, 1, \$fxs);
    check_type($pattern, "Z3_pattern", "pattern is correct type");

    my $pattern_string = Z3::FFI::pattern_to_string($ctx, $pattern);
    is($pattern_string, $pattern_test, "Pattern matches expected layout");

    my $q = Z3::FFI::mk_forall($ctx, 0, 1, \$pattern, $sz, \@types, \@names, $equal);
    check_type($q, "Z3_ast", "Quantifier comes back correctly");

    my $q_str = Z3::FFI::ast_to_string($ctx, $q);
    is($q_str, "WHAT", "Quantifier is correct value");
    Z3::FFI::solver_assert($ctx, $solver, $q);
}

sub assert_comm_axiom {
    my ($ctx, $solver, $f, $axiom_value) = @_;

    my $t = Z3::FFI::get_range($ctx, $f);
    check_type($t, "Z3_sort", "Function range correct type");

    my $d_size = Z3::FFI::get_domain_size($ctx, $f);
    my $d1 = Z3::FFI::get_domain($ctx, $f, 0);
    my $d2 = Z3::FFI::get_domain($ctx, $f, 1);

    check_type($d1, "Z3_sort", "Domain 1 is correct type");
    check_type($d2, "Z3_sort", "Domain 2 is correct type");

    # I'm not 100% that I'm doing this check with $$d1, $$d2, and $$t correctly
    if ($d_size != 2 || $$d1 != $$t || $$d2 != $$t) {
        fail("Function must be binary and argument types must be equal to return types");
        die "Failed function input in test";
    }

    my $f_name = Z3::FFI::mk_string_symbol($ctx, "f");
    my $t_name = Z3::FFI::mk_string_symbol($ctx, "T");

    check_type($f_name, "Z3_symbol", "function name is correct type");
    check_type($t_name, "Z3_symbol", "Type name is correct type");

    my $q = Z3::FFI::parse_smtlib2_string($ctx, "(assert (forall ((x T) (y T)) (= f x y) (f y x))))",
                                          1, \$t_name, \$t,
                                          1, \$f_name, \$f);

    check_type($q, "Z3_ast_vector", "Q type is correct");
    my $axiom_string = Z3::FFI::ast_vector_to_string($ctx, $q);
    is($axiom_string, $axiom_value, "Axiom is expected value");

    my $vector_size = Z3::FFI::ast_vector_size($ctx, $q);
    for (my $i = 0; $i < $vector_size; $i++) {
        Z3::FFI::solver_assert($ctx, $solver, Z3::FFI::ast_vector_get($ctx, $q, $i));
    }

    return;
}

1;