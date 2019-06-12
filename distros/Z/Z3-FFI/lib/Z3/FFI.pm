package Z3::FFI;

use strict;
use warnings;

our $VERSION = '0.003';

use Data::Dumper;
use FFI::Platypus;
use FFI::CheckLib qw//;
use FFI::Platypus::API qw/arguments_get_string/;
use File::ShareDir qw/dist_dir/;
use Path::Tiny;

my $search_path = path(dist_dir('Alien-Z3'))->child('dynamic');
my $ffi_lib = FFI::CheckLib::find_lib_or_die(lib => 'z3', libpath => $search_path);
my $ffi = FFI::Platypus->new();
$ffi->lib($ffi_lib);

use constant {
  # Z3_bool
  Z3_TRUE => 1,
  Z3_FALSE => 0,
  # Z3_lbool
  Z3_L_FALSE => -1,
  Z3_L_UNDEF => 0,
  Z3_L_TRUE => 1,
  # Z3_symbol_kind
  Z3_INT_SYMBOL => 0,
  Z3_STRING_SYMBOL => 1,
  # Z3_paramter_kind
  Z3_PARAMETER_INT => 0,
  Z3_PARAMETER_DOUBLE => 1,
  Z3_PARAMETER_RATIONAL => 2,
  Z3_PARAMETER_SYMBOL => 3,
  Z3_PARAMETER_SORT => 4,
  Z3_PARAMETER_AST => 5,
  Z3_PARAMETER_FUNC_DECL => 6,
  # Z3_sort_kind
  Z3_UNINTERRUPTED_SORT => 0,
  Z3_BOOL_SORT => 1,
  Z3_INT_SORT => 2,
  Z3_REAL_SORT => 3,
  Z3_BV_SORT => 4,
  Z3_ARRAY_SORT => 5,
  Z3_DATATYPE_SORT => 6,
  Z3_RELATION_SORT => 7,
  Z3_FINITE_DOMAIN_SORT => 8,
  Z3_FLOATING_POINT_SORT => 9,
  Z3_ROUNDING_MODE_SORT => 10,
  Z3_SEQ_SORT => 11,
  Z3_RE_SORT => 12,
  Z3_UNKNOWN_SORT => 1000,
  # Z3_ast_kind
  Z3_NUMERAL_AST => 0,
  Z3_APP_AST => 1,
  Z3_VAR_AST => 2,
  Z3_QUANTIFIER_AST => 3,
  Z3_SORT_AST => 4,
  Z3_FUNC_DECL_AST => 5,
  Z3_UNKNOWN_AST => 1000,
  # Z3_param_kind
  Z3_PK_UINT => 0,
  Z3_PK_BOOL => 1,
  Z3_PK_DOUBLE => 2,
  Z3_PK_SYMBOL => 3,
  Z3_PK_STRING => 4,
  Z3_PK_OTHER => 5,
  Z3_PK_INVALID => 6,
  # Z3_ast_print_mode
  Z3_PRINT_SMTLIB_FULL => 0,
  Z3_PRINT_LOW_LEVEL => 1,
  Z3_PRINT_SMTLIB2_COMPLIANT => 2,
  # Z3_error_code
  Z3_OK => 0,
  Z3_SORT_ERROR => 1,
  Z3_IOB => 2,
  Z3_INVALID_ARG => 3,
  Z3_PARSER_ERROR => 4,
  Z3_NO_PARSER => 5,
  Z3_INVALID_PATTERN => 6,
  Z3_MEMOUT_FAIL => 7,
  Z3_FILE_ACCESS_ERROR => 8,
  Z3_INTERNAL_FATAL => 9,
  Z3_INVALID_USAGE => 10,
  Z3_DEC_REF_ERROR => 11,
  Z3_EXCEPTION => 12,
  # Z3_goal_prec
  Z3_GOAL_PRECISE => 0,
  Z3_GOAL_UNDER => 1,
  Z3_GOAL_OVER => 2,
  Z3_GOAL_UNDER_OVER => 3,
  # Z3_decl_kind
  Z3_OP_TRUE => 256, Z3_OP_FALSE => 257, Z3_OP_EQ => 258, Z3_OP_DISTINCT => 259, 
  Z3_OP_ITE => 260, Z3_OP_AND => 261, Z3_OP_OR => 262, Z3_OP_IFF => 263, 
  Z3_OP_XOR => 264, Z3_OP_NOT => 265, Z3_OP_IMPLIES => 266, Z3_OP_OEQ => 267, 
  Z3_OP_ANUM => 512, Z3_OP_AGNUM => 513, Z3_OP_LE => 514, Z3_OP_GE => 515, 
  Z3_OP_LT => 516, Z3_OP_GT => 517, Z3_OP_ADD => 518, Z3_OP_SUB => 519, 
  Z3_OP_UMINUS => 520, Z3_OP_MUL => 521, Z3_OP_DIV => 522, Z3_OP_IDIV => 523, 
  Z3_OP_REM => 524, Z3_OP_MOD => 525, Z3_OP_TO_REAL => 526, Z3_OP_TO_INT => 527, 
  Z3_OP_IS_INT => 528, Z3_OP_POWER => 529, Z3_OP_STORE => 768, Z3_OP_SELECT => 769, 
  Z3_OP_CONST_ARRAY => 770, Z3_OP_ARRAY_MAP => 771, Z3_OP_ARRAY_DEFAULT => 772, Z3_OP_SET_UNION => 773, 
  Z3_OP_SET_INTERSECT => 774, Z3_OP_SET_DIFFERENCE => 775, Z3_OP_SET_COMPLEMENT => 776, Z3_OP_SET_SUBSET => 777, 
  Z3_OP_AS_ARRAY => 778, Z3_OP_ARRAY_EXT => 779, Z3_OP_BNUM => 1024, Z3_OP_BIT1 => 1025, 
  Z3_OP_BIT0 => 1026, Z3_OP_BNEG => 1027, Z3_OP_BADD => 1028, Z3_OP_BSUB => 1029, 
  Z3_OP_BMUL => 1030, Z3_OP_BSDIV => 1031, Z3_OP_BUDIV => 1032, Z3_OP_BSREM => 1033, 
  Z3_OP_BUREM => 1034, Z3_OP_BSMOD => 1035, Z3_OP_BSDIV0 => 1036, Z3_OP_BUDIV0 => 1037, 
  Z3_OP_BSREM0 => 1038, Z3_OP_BUREM0 => 1039, Z3_OP_BSMOD0 => 1040, Z3_OP_ULEQ => 1041, 
  Z3_OP_SLEQ => 1042, Z3_OP_UGEQ => 1043, Z3_OP_SGEQ => 1044, Z3_OP_ULT => 1045, 
  Z3_OP_SLT => 1046, Z3_OP_UGT => 1047, Z3_OP_SGT => 1048, Z3_OP_BAND => 1049, 
  Z3_OP_BOR => 1050, Z3_OP_BNOT => 1051, Z3_OP_BXOR => 1052, Z3_OP_BNAND => 1053, 
  Z3_OP_BNOR => 1054, Z3_OP_BXNOR => 1055, Z3_OP_CONCAT => 1056, Z3_OP_SIGN_EXT => 1057, 
  Z3_OP_ZERO_EXT => 1058, Z3_OP_EXTRACT => 1059, Z3_OP_REPEAT => 1060, Z3_OP_BREDOR => 1061, 
  Z3_OP_BREDAND => 1062, Z3_OP_BCOMP => 1063, Z3_OP_BSHL => 1064, Z3_OP_BLSHR => 1065, 
  Z3_OP_BASHR => 1066, Z3_OP_ROTATE_LEFT => 1067, Z3_OP_ROTATE_RIGHT => 1068, Z3_OP_EXT_ROTATE_LEFT => 1069, 
  Z3_OP_EXT_ROTATE_RIGHT => 1070, Z3_OP_BIT2BOOL => 1071, Z3_OP_INT2BV => 1072, Z3_OP_BV2INT => 1073, 
  Z3_OP_CARRY => 1074, Z3_OP_XOR3 => 1075, Z3_OP_BSMUL_NO_OVFL => 1076, Z3_OP_BUMUL_NO_OVFL => 1077, 
  Z3_OP_BSMUL_NO_UDFL => 1078, Z3_OP_BSDIV_I => 1079, Z3_OP_BUDIV_I => 1080, Z3_OP_BSREM_I => 1081, 
  Z3_OP_BUREM_I => 1082, Z3_OP_BSMOD_I => 1083, Z3_OP_PR_UNDEF => 1280, Z3_OP_PR_TRUE => 1281, 
  Z3_OP_PR_ASSERTED => 1282, Z3_OP_PR_GOAL => 1283, Z3_OP_PR_MODUS_PONENS => 1284, Z3_OP_PR_REFLEXIVITY => 1285, 
  Z3_OP_PR_SYMMETRY => 1286, Z3_OP_PR_TRANSITIVITY => 1287, Z3_OP_PR_TRANSITIVITY_STAR => 1288, Z3_OP_PR_MONOTONICITY => 1289, 
  Z3_OP_PR_QUANT_INTRO => 1290, Z3_OP_PR_BIND => 1291, Z3_OP_PR_DISTRIBUTIVITY => 1292, Z3_OP_PR_AND_ELIM => 1293, 
  Z3_OP_PR_NOT_OR_ELIM => 1294, Z3_OP_PR_REWRITE => 1295, Z3_OP_PR_REWRITE_STAR => 1296, Z3_OP_PR_PULL_QUANT => 1297, 
  Z3_OP_PR_PUSH_QUANT => 1298, Z3_OP_PR_ELIM_UNUSED_VARS => 1299, Z3_OP_PR_DER => 1300, Z3_OP_PR_QUANT_INST => 1301, 
  Z3_OP_PR_HYPOTHESIS => 1302, Z3_OP_PR_LEMMA => 1303, Z3_OP_PR_UNIT_RESOLUTION => 1304, Z3_OP_PR_IFF_TRUE => 1305, 
  Z3_OP_PR_IFF_FALSE => 1306, Z3_OP_PR_COMMUTATIVITY => 1307, Z3_OP_PR_DEF_AXIOM => 1308, Z3_OP_PR_DEF_INTRO => 1309, 
  Z3_OP_PR_APPLY_DEF => 1310, Z3_OP_PR_IFF_OEQ => 1311, Z3_OP_PR_NNF_POS => 1312, Z3_OP_PR_NNF_NEG => 1313, 
  Z3_OP_PR_SKOLEMIZE => 1314, Z3_OP_PR_MODUS_PONENS_OEQ => 1315, Z3_OP_PR_TH_LEMMA => 1316, Z3_OP_PR_HYPER_RESOLVE => 1317, 
  Z3_OP_RA_STORE => 1536, Z3_OP_RA_EMPTY => 1537, Z3_OP_RA_IS_EMPTY => 1538, Z3_OP_RA_JOIN => 1539, 
  Z3_OP_RA_UNION => 1540, Z3_OP_RA_WIDEN => 1541, Z3_OP_RA_PROJECT => 1542, Z3_OP_RA_FILTER => 1543, 
  Z3_OP_RA_NEGATION_FILTER => 1544, Z3_OP_RA_RENAME => 1545, Z3_OP_RA_COMPLEMENT => 1546, Z3_OP_RA_SELECT => 1547, 
  Z3_OP_RA_CLONE => 1548, Z3_OP_FD_CONSTANT => 1549, Z3_OP_FD_LT => 1550, Z3_OP_SEQ_UNIT => 1551, 
  Z3_OP_SEQ_EMPTY => 1552, Z3_OP_SEQ_CONCAT => 1553, Z3_OP_SEQ_PREFIX => 1554, Z3_OP_SEQ_SUFFIX => 1555, 
  Z3_OP_SEQ_CONTAINS => 1556, Z3_OP_SEQ_EXTRACT => 1557, Z3_OP_SEQ_REPLACE => 1558, Z3_OP_SEQ_AT => 1559, 
  Z3_OP_SEQ_LENGTH => 1560, Z3_OP_SEQ_INDEX => 1561, Z3_OP_SEQ_TO_RE => 1562, Z3_OP_SEQ_IN_RE => 1563, 
  Z3_OP_STR_TO_INT => 1564, Z3_OP_INT_TO_STR => 1565, Z3_OP_RE_PLUS => 1566, Z3_OP_RE_STAR => 1567, 
  Z3_OP_RE_OPTION => 1568, Z3_OP_RE_CONCAT => 1569, Z3_OP_RE_UNION => 1570, Z3_OP_RE_RANGE => 1571, 
  Z3_OP_RE_LOOP => 1572, Z3_OP_RE_INTERSECT => 1573, Z3_OP_RE_EMPTY_SET => 1574, Z3_OP_RE_FULL_SET => 1575, 
  Z3_OP_RE_COMPLEMENT => 1576, Z3_OP_LABEL => 1792, Z3_OP_LABEL_LIT => 1793, Z3_OP_DT_CONSTRUCTOR => 2048, 
  Z3_OP_DT_RECOGNISER => 2049, Z3_OP_DT_IS => 2050, Z3_OP_DT_ACCESSOR => 2051, Z3_OP_DT_UPDATE_FIELD => 2052, 
  Z3_OP_PB_AT_MOST => 2304, Z3_OP_PB_AT_LEAST => 2305, Z3_OP_PB_LE => 2306, Z3_OP_PB_GE => 2307, 
  Z3_OP_PB_EQ => 2308, Z3_OP_FPA_RM_NEAREST_TIES_TO_EVEN => 2309, Z3_OP_FPA_RM_NEAREST_TIES_TO_AWAY => 2310, Z3_OP_FPA_RM_TOWARD_POSITIVE => 2311, 
  Z3_OP_FPA_RM_TOWARD_NEGATIVE => 2312, Z3_OP_FPA_RM_TOWARD_ZERO => 2313, Z3_OP_FPA_NUM => 2314, Z3_OP_FPA_PLUS_INF => 2315, 
  Z3_OP_FPA_MINUS_INF => 2316, Z3_OP_FPA_NAN => 2317, Z3_OP_FPA_PLUS_ZERO => 2318, Z3_OP_FPA_MINUS_ZERO => 2319, 
  Z3_OP_FPA_ADD => 2320, Z3_OP_FPA_SUB => 2321, Z3_OP_FPA_NEG => 2322, Z3_OP_FPA_MUL => 2323, 
  Z3_OP_FPA_DIV => 2324, Z3_OP_FPA_REM => 2325, Z3_OP_FPA_ABS => 2326, Z3_OP_FPA_MIN => 2327, 
  Z3_OP_FPA_MAX => 2328, Z3_OP_FPA_FMA => 2329, Z3_OP_FPA_SQRT => 2330, Z3_OP_FPA_ROUND_TO_INTEGRAL => 2331, 
  Z3_OP_FPA_EQ => 2332, Z3_OP_FPA_LT => 2333, Z3_OP_FPA_GT => 2334, Z3_OP_FPA_LE => 2335, 
  Z3_OP_FPA_GE => 2336, Z3_OP_FPA_IS_NAN => 2337, Z3_OP_FPA_IS_INF => 2338, Z3_OP_FPA_IS_ZERO => 2339, 
  Z3_OP_FPA_IS_NORMAL => 2340, Z3_OP_FPA_IS_SUBNORMAL => 2341, Z3_OP_FPA_IS_NEGATIVE => 2342, Z3_OP_FPA_IS_POSITIVE => 2343, 
  Z3_OP_FPA_FP => 2344, Z3_OP_FPA_TO_FP => 2345, Z3_OP_FPA_TO_FP_UNSIGNED => 2346, Z3_OP_FPA_TO_UBV => 2347, 
  Z3_OP_FPA_TO_SBV => 2348, Z3_OP_FPA_TO_REAL => 2349, Z3_OP_FPA_TO_IEEE_BV => 2350, Z3_OP_FPA_BVWRAP => 2351, 
  Z3_OP_FPA_BV2RM => 2352, Z3_OP_INTERNAL => 2353, Z3_OP_UNINTERPRETED => 2354
};

my $opaque_types = [map {"Z3_$_"} qw/config context symbol ast sort func_decl app pattern constructor constructor_list params param_descrs model func_interp func_entry fixedpoint optimize ast_vector ast_map goal tactic probe apply_result solver stats rcf_num/];

my $functions = [
  [mk_fixedpoint => ["Z3_context"] => "Z3_fixedpoint"],
  [fixedpoint_inc_ref => ["Z3_context", "Z3_fixedpoint"] => "void"],
  [fixedpoint_dec_ref => ["Z3_context", "Z3_fixedpoint"] => "void"],
  [fixedpoint_add_rule => ["Z3_context", "Z3_fixedpoint", "Z3_ast", "Z3_symbol"] => "void"],
  [fixedpoint_add_fact => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl", "uint", "uint[]"] => "void"],
  [fixedpoint_assert => ["Z3_context", "Z3_fixedpoint", "Z3_ast"] => "void"],
  [fixedpoint_query => ["Z3_context", "Z3_fixedpoint", "Z3_ast"] => "Z3_lbool"],
  [fixedpoint_query_relations => ["Z3_context", "Z3_fixedpoint", "uint", "Z3_func_decl_arr"] => "Z3_lbool"],
  [fixedpoint_get_answer => ["Z3_context", "Z3_fixedpoint"] => "Z3_ast"],
  [fixedpoint_get_reason_unknown => ["Z3_context", "Z3_fixedpoint"] => "Z3_string"],
  [fixedpoint_update_rule => ["Z3_context", "Z3_fixedpoint", "Z3_ast", "Z3_symbol"] => "void"],
  [fixedpoint_get_num_levels => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl"] => "uint"],
  [fixedpoint_get_cover_delta => ["Z3_context", "Z3_fixedpoint", "int", "Z3_func_decl"] => "Z3_ast"],
  [fixedpoint_add_cover => ["Z3_context", "Z3_fixedpoint", "int", "Z3_func_decl", "Z3_ast"] => "void"],
  [fixedpoint_get_statistics => ["Z3_context", "Z3_fixedpoint"] => "Z3_stats"],
  [fixedpoint_register_relation => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl"] => "void"],
  [fixedpoint_set_predicate_representation => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl", "uint", "Z3_symbol_arr"] => "void"],
  [fixedpoint_get_rules => ["Z3_context", "Z3_fixedpoint"] => "Z3_ast_vector"],
  [fixedpoint_get_assertions => ["Z3_context", "Z3_fixedpoint"] => "Z3_ast_vector"],
  [fixedpoint_set_params => ["Z3_context", "Z3_fixedpoint", "Z3_params"] => "void"],
  [fixedpoint_get_help => ["Z3_context", "Z3_fixedpoint"] => "Z3_string"],
  [fixedpoint_get_param_descrs => ["Z3_context", "Z3_fixedpoint"] => "Z3_param_descrs"],
  [fixedpoint_to_string => ["Z3_context", "Z3_fixedpoint", "uint", "Z3_ast_arr"] => "Z3_string"],
  [fixedpoint_from_string => ["Z3_context", "Z3_fixedpoint", "Z3_string"] => "Z3_ast_vector"],
  [fixedpoint_from_file => ["Z3_context", "Z3_fixedpoint", "Z3_string"] => "Z3_ast_vector"],
  [fixedpoint_push => ["Z3_context", "Z3_fixedpoint"] => "void"],
  [fixedpoint_pop => ["Z3_context", "Z3_fixedpoint"] => "void"],
  [fixedpoint_init => ["Z3_context", "Z3_fixedpoint", "void*"] => "void"],
  #[fixedpoint_set_reduce_assign_callback => ["Z3_context", "Z3_fixedpoint", "Z3_fixedpoint_reduce_assign_callback_fptr"] => "void"], # TODO figure out these functions?
  #[fixedpoint_set_reduce_app_callback => ["Z3_context", "Z3_fixedpoint", "Z3_fixedpoint_reduce_app_callback_fptr"] => "void"],
  #[fixedpoint_add_callback => ["Z3_context", "Z3_fixedpoint", "void *state", "Z3_fixedpoint_new_lemma_eh", "Z3_fixedpoint_predecessor_eh", "Z3_fixedpoint_unfold_eh"] => "void"],
  [fixedpoint_add_constraint  => ["Z3_context", "Z3_fixedpoint", "Z3_ast", "uint"] => "void"],
  [fixedpoint_query_from_lvl  => ["Z3_context", "Z3_fixedpoint", "Z3_ast", "uint"] => "Z3_lbool"],
  [fixedpoint_get_ground_sat_answer => ["Z3_context", "Z3_fixedpoint"] => "Z3_ast"],
  [fixedpoint_get_rules_along_trace => ["Z3_context", "Z3_fixedpoint"] => "Z3_ast_vector"],
  [fixedpoint_get_rule_names_along_trace => ["Z3_context", "Z3_fixedpoint"] => "Z3_symbol"],
  [fixedpoint_add_invariant => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl", "Z3_ast"] => "void"],
  [fixedpoint_get_reachable => ["Z3_context", "Z3_fixedpoint", "Z3_func_decl"] => "Z3_ast"],
  [qe_model_project => ["Z3_context", "Z3_model", "uint", "Z3_app_arr", "Z3_ast"] => "Z3_ast"],
  [qe_model_project_skolem => ["Z3_context", "Z3_model", "uint", "Z3_app_arr", "Z3_ast", "Z3_ast_map"] => "Z3_ast"],
  [model_extrapolate  => ["Z3_context", "Z3_model", "Z3_ast"] => "Z3_ast"],
  [qe_lite  => ["Z3_context", "Z3_ast_vector", "Z3_ast"] => "Z3_ast"],
  [polynomial_subresultants => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast_vector"],
  [global_param_set => ["Z3_string", "Z3_string"] => "void"],
  [global_param_reset_all => [] => "void"],
  [global_param_get => ["Z3_string", "Z3_string_ptr"] => "Z3_bool"],
  [mk_config => [] => "Z3_config"],
  [del_config => ["Z3_config"] => "void"],
  [set_param_value => ["Z3_config", "Z3_string", "Z3_string"] => "void"],
  [mk_context => ["Z3_config"] => "Z3_context"],
  [mk_context_rc => ["Z3_config"] => "Z3_context"],
  [del_context => ["Z3_context"] => "void"],
  [inc_ref => ["Z3_context", "Z3_ast"] => "void"],
  [dec_ref => ["Z3_context", "Z3_ast"] => "void"],
  [update_param_value => ["Z3_context", "Z3_string", "Z3_string"] => "void"],
  [interrupt => ["Z3_context"] => "void"],
  [mk_params => ["Z3_context"] => "Z3_params"],
  [params_inc_ref => ["Z3_context", "Z3_params"] => "void"],
  [params_dec_ref => ["Z3_context", "Z3_params"] => "void"],
  [params_set_bool => ["Z3_context", "Z3_params", "Z3_symbol", "bool"] => "void"],
  [params_set_uint => ["Z3_context", "Z3_params", "Z3_symbol", "uint"] => "void"],
  [params_set_double => ["Z3_context", "Z3_params", "Z3_symbol", "double"] => "void"],
  [params_set_symbol => ["Z3_context", "Z3_params", "Z3_symbol", "Z3_symbol"] => "void"],
  [params_to_string => ["Z3_context", "Z3_params"] => "Z3_string"],
  [params_validate => ["Z3_context", "Z3_params", "Z3_param_descrs"] => "void"],
  [param_descrs_inc_ref => ["Z3_context", "Z3_param_descrs"] => "void"],
  [param_descrs_dec_ref => ["Z3_context", "Z3_param_descrs"] => "void"],
  [param_descrs_get_kind => ["Z3_context", "Z3_param_descrs", "Z3_symbol"] => "Z3_param_kind"],
  [param_descrs_size => ["Z3_context", "Z3_param_descrs"] => "uint"],
  [param_descrs_get_name => ["Z3_context", "Z3_param_descrs", "uint"] => "Z3_symbol"],
  [param_descrs_get_documentation => ["Z3_context", "Z3_param_descrs", "Z3_symbol"] => "Z3_string"],
  [param_descrs_to_string => ["Z3_context", "Z3_param_descrs"] => "Z3_string"],
  [mk_int_symbol => ["Z3_context", "int"] => "Z3_symbol"],
  [mk_string_symbol => ["Z3_context", "Z3_string"] => "Z3_symbol"],
  [mk_uninterpreted_sort => ["Z3_context", "Z3_symbol"] => "Z3_sort"],
  [mk_bool_sort => ["Z3_context"] => "Z3_sort"],
  [mk_int_sort => ["Z3_context"] => "Z3_sort"],
  [mk_real_sort => ["Z3_context"] => "Z3_sort"],
  [mk_bv_sort => ["Z3_context", "uint"] => "Z3_sort"],
  [mk_finite_domain_sort => ["Z3_context", "Z3_symbol", "uint64_t"] => "Z3_sort"],
  [mk_array_sort => ["Z3_context", "Z3_sort", "Z3_sort"] => "Z3_sort"],
  [mk_array_sort_n => ["Z3_context", "uint", "Z3_sort_ptr", "Z3_sort"] => "Z3_sort", sub {
    my ($xsub, $ctx, $n, $domain, $range) = @_;
    die "\$domain needs to be passed as a scalar reference to mk_array_sort_n" unless ref($domain) eq 'SCALAR';

    my $ret = $xsub->($ctx, $n, $domain, $range);
    my $pointer = $$domain;
    # rebless the inner object into the right type for later
    $$domain = bless \$pointer, "Z3::FFI::Types::Z3_sort";

    return $ret;
  }],
  [mk_tuple_sort => ["Z3_context", "Z3_symbol", "uint", "Z3_symbol_arr", "Z3_sort_arr", "Z3_func_decl_ptr", "Z3_func_decl_arr"] => "Z3_sort", sub {
    my ($xsub, $ctx, $mk_tuple_name, $num_fields, $field_names, $field_sorts, $mk_tuple_decl, $proj_decl) = @_;
    my $ct_names = scalar @$field_names;
    my $ct_sorts = scalar @$field_sorts;
    die "Number of field names ($ct_names) doesn't match \$num_fields ($num_fields)" unless $ct_names == $num_fields;
    die "Number of field sorts ($ct_sorts) doesn't match \$num_fields ($num_fields)" unless $ct_sorts == $num_fields;
    die "\$mk_tuple_decl needs to be passed as a scalar reference to mk_tuple_sort" unless ref($mk_tuple_decl) eq 'SCALAR';
    # set the array here to be long enough
    @{$proj_decl} = (undef() x $num_fields);

    my $ret = $xsub->($ctx, $mk_tuple_name, $num_fields, $field_names, $field_sorts, $mk_tuple_decl, $proj_decl);
    my $pointer = $$mk_tuple_decl;
    # rebless the inner object into the right type for later
    $$mk_tuple_decl = bless \$pointer, "Z3::FFI::Types::Z3_func_decl";

    return $ret;
  }],
  [mk_enumeration_sort => ["Z3_context", "Z3_symbol", "uint", "Z3_symbol_arr", "Z3_func_decl_arr", "Z3_func_decl_arr"] => "Z3_sort"],
  [mk_list_sort => ["Z3_context", "Z3_symbol", "Z3_sort", "Z3_func_decl_ptr", "Z3_func_decl_ptr", "Z3_func_decl_ptr", "Z3_func_decl_ptr", "Z3_func_decl_ptr", "Z3_func_decl_ptr"] => "Z3_sort", sub {
    my ($xsub, $ctx, $name, $elem_sort, $nil_decl, $is_nil_decl, $cons_decl, $is_cons_decl, $head_decl, $tail_decl) = @_;
    die "\$nil_decl needs to be passed as a scalar reference to mk_list_sort"     unless ref($nil_decl) eq 'SCALAR';
    die "\$is_nil_decl needs to be passed as a scalar reference to mk_list_sort"  unless ref($is_nil_decl) eq 'SCALAR';
    die "\$cons_decl needs to be passed as a scalar reference to mk_list_sort"    unless ref($cons_decl) eq 'SCALAR';
    die "\$is_cons_decl needs to be passed as a scalar reference to mk_list_sort" unless ref($is_cons_decl) eq 'SCALAR';
    die "\$head_decl needs to be passed as a scalar reference to mk_list_sort"    unless ref($head_decl) eq 'SCALAR';
    die "\$tail_decl needs to be passed as a scalar reference to mk_list_sort"    unless ref($tail_decl) eq 'SCALAR';

    my $ret = $xsub->($ctx, $name, $elem_sort, $nil_decl, $is_nil_decl, $cons_decl, $is_cons_decl, $head_decl, $tail_decl);
    my $pointer = $$nil_decl;
    $$nil_decl = bless \$pointer, "Z3::FFI::Types::Z3_func_decl";
    my $pointer2 = $$is_nil_decl;
    $$is_nil_decl = bless \$pointer2, "Z3::FFI::Types::Z3_func_decl";
    my $pointer3 = $$cons_decl;
    $$cons_decl = bless \$pointer3, "Z3::FFI::Types::Z3_func_decl";
    my $pointer4 = $$is_cons_decl;
    $$is_cons_decl = bless \$pointer4, "Z3::FFI::Types::Z3_func_decl";
    my $pointer5 = $$head_decl;
    $$head_decl = bless \$pointer, "Z3::FFI::Types::Z3_func_decl";
    my $pointer6 = $$tail_decl;
    $$tail_decl = bless \$pointer6, "Z3::FFI::Types::Z3_func_decl";
    
    return $ret;
  }],
  [mk_constructor => ["Z3_context", "Z3_symbol", "Z3_symbol", "uint", "Z3_symbol_arr", "Z3_sort_arr", "uint[]"] => "Z3_constructor", sub {
    my ($xsub, $ctx, $name, $recognizer, $num_fields, $field_names, $sorts, $sort_refs) = @_;
    my $ct_field_names = scalar @$field_names;
    die "Number of field_names ($ct_field_names) doesn't match \$num_fields ($num_fields)" unless $ct_field_names == $num_fields;

    $xsub->($ctx, $name, $recognizer, $num_fields, $field_names, $sorts, $sort_refs);
  }],
  [del_constructor => ["Z3_context", "Z3_constructor"] => "void"],
  [mk_datatype => ["Z3_context", "Z3_symbol", "uint", "Z3_constructor_arr"] => "Z3_sort"],
  [mk_constructor_list => ["Z3_context", "uint", "Z3_constructor_arr"] => "Z3_constructor_list"],
  [del_constructor_list => ["Z3_context", "Z3_constructor_list"] => "void"],
  [mk_datatypes => ["Z3_context", "uint", "Z3_symbol_arr", "Z3_sort_arr", "Z3_constructor_list_arr"] => "void"],
  [query_constructor => ["Z3_context", "Z3_constructor", "uint", "Z3_func_decl_ptr", "Z3_func_decl_ptr", "Z3_func_decl_arr"] => "void", sub {
    my ($xsub, $ctx, $constructor, $num_fields, $func_constructor, $func_tester, $accessors) = @_;
    my $ct_accessors = scalar @$accessors;
    die "Number of accessors ($ct_accessors) doesn't match \$num_fields ($num_fields)" unless $ct_accessors == $num_fields;
    die "\$func_constructor needs to be passed as a scalar reference to query_constructor" unless ref($func_constructor) eq 'SCALAR';
    die "\$func_tester needs to be passed as a scalar reference to query_constructor" unless ref($func_constructor) eq 'SCALAR';

    my $ret = $xsub->($ctx, $constructor, $num_fields, $func_constructor, $func_tester, $accessors);
    my $pointer = $$func_tester;
    my $pointer2 = $$func_constructor;
    # rebless the inner object into the right type for later
    $$func_tester = bless \$pointer, "Z3::FFI::Types::Z3_func_decl";
    $$func_constructor = bless \$pointer2, "Z3::FFI::Types::Z3_func_decl";
    
    return $ret;
  }],
  [mk_func_decl => ["Z3_context", "Z3_symbol", "uint", "Z3_sort_arr", "Z3_sort"] => "Z3_func_decl"],
  [mk_app => ["Z3_context", "Z3_func_decl", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_const => ["Z3_context", "Z3_symbol", "Z3_sort"] => "Z3_ast"],
  [mk_fresh_func_decl => ["Z3_context", "Z3_string", "uint", "Z3_sort_arr", "Z3_sort"] => "Z3_func_decl"],
  [mk_fresh_const => ["Z3_context", "Z3_string", "Z3_sort"] => "Z3_ast"],
  [mk_rec_func_decl => ["Z3_context", "Z3_symbol", "uint", "Z3_sort_arr", "Z3_sort"] => "Z3_func_decl"],
  [add_rec_def => ["Z3_context", "Z3_func_decl", "uint", "Z3_ast_arr", "Z3_ast"] => "void"],
  [mk_true => ["Z3_context"] => "Z3_ast"],
  [mk_false => ["Z3_context"] => "Z3_ast"],
  [mk_eq => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_distinct => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_not => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_ite => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_iff => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_implies => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_xor => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_and => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_or => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_add => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_mul => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_sub => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_unary_minus => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_div => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_mod => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_rem => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_power => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_lt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_le => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_gt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_ge => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_int2real => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_real2int => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_is_int => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvnot => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvredand => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvredor => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvand => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvor => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvxor => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvnand => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvnor => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvxnor => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvneg => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvadd => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsub => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvmul => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvudiv => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsdiv => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvurem => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsrem => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsmod => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvult => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvslt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvule => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsle => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvuge => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsge => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvugt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsgt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_concat => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_extract => ["Z3_context", "uint", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_sign_ext => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_zero_ext => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_repeat => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_bvshl => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvlshr => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvashr => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_rotate_left => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_rotate_right => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_ext_rotate_left => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_ext_rotate_right => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_int2bv => ["Z3_context", "uint", "Z3_ast"] => "Z3_ast"],
  [mk_bv2int => ["Z3_context", "Z3_ast", "bool"] => "Z3_ast"],
  [mk_bvadd_no_overflow => ["Z3_context", "Z3_ast", "Z3_ast", "bool"] => "Z3_ast"],
  [mk_bvadd_no_underflow => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsub_no_overflow => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvsub_no_underflow => ["Z3_context", "Z3_ast", "Z3_ast", "bool"] => "Z3_ast"],
  [mk_bvsdiv_no_overflow => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_bvneg_no_overflow => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_bvmul_no_overflow => ["Z3_context", "Z3_ast", "Z3_ast", "bool"] => "Z3_ast"],
  [mk_bvmul_no_underflow => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_select => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_select_n => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr"] => "Z3_ast", sub {
    my ($xsub, $ctx, $ast, $ct, $indexes) = @_;
    # subtract one, $indexes is going to be NULL terminated, which doesn't matter for this call
    # so the count will be off by one from what we got passed
    die "\$ct($ct) and \$indexes(".(@$indexes-1).") don't match" unless $ct == @$indexes-1;

    $xsub->($ctx, $ast, $ct, $indexes);
  }],
  [mk_store => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_store_n => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr", "Z3_ast"] => "Z3_ast", sub {
    my ($xsub, $ctx, $ast, $ct, $indexes, $val) = @_;
    # subtract one, $indexes is going to be NULL terminated, which doesn't matter for this call
    # so the count will be off by one from what we got passed
    die "\$ct($ct) and \$indexes(".(@$indexes-1).") don't match" unless $ct == @$indexes-1;

    $xsub->($ctx, $ast, $ct, $indexes, $val);
  }],
  [mk_const_array => ["Z3_context", "Z3_sort", "Z3_ast"] => "Z3_ast"],
  [mk_map => ["Z3_context", "Z3_func_decl", "uint", "Z3_ast_arr"] => "Z3_ast", sub {
    my ($xsub, $ctx, $ast, $ct, $args) = @_;
    # subtract one, $indexes is going to be NULL terminated, which doesn't matter for this call
    # so the count will be off by one from what we got passed
    die "\$ct($ct) and \$args(".(@$args-1).") don't match" unless $ct == @$args-1;

    $xsub->($ctx, $ast, $ct, $args);
  }],
  [mk_array_default => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_as_array => ["Z3_context", "Z3_func_decl"] => "Z3_ast"],
  [mk_set_sort => ["Z3_context", "Z3_sort"] => "Z3_sort"],
  [mk_empty_set => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_full_set => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_set_add => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_set_del => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_set_union => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_set_intersect => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_set_difference => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_set_complement => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_set_member => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_set_subset => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_array_ext => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_numeral => ["Z3_context", "Z3_string", "Z3_sort"] => "Z3_ast"],
  [mk_real => ["Z3_context", "int", "int"] => "Z3_ast"],
  [mk_int => ["Z3_context", "int", "Z3_sort"] => "Z3_ast"],
#  [mk_uint_int => ["Z3_context", "uint", "Z3_sort"] => "Z3_ast"], # TODO not found in library
  [mk_int64 => ["Z3_context", "int64_t", "Z3_sort"] => "Z3_ast"],
#  [mk_uint_int64 => ["Z3_context", "uint64_t", "Z3_sort"] => "Z3_ast"], # TODO not found in library
  [mk_bv_numeral => ["Z3_context", "uint", "bool*"] => "Z3_ast"],
  [mk_seq_sort => ["Z3_context", "Z3_sort"] => "Z3_sort"],
  [is_seq_sort => ["Z3_context", "Z3_sort"] => "bool"],
  [mk_re_sort => ["Z3_context", "Z3_sort"] => "Z3_sort"],
  [is_re_sort => ["Z3_context", "Z3_sort"] => "bool"],
  [mk_string_sort => ["Z3_context"] => "Z3_sort"],
  [is_string_sort => ["Z3_context", "Z3_sort"] => "bool"],
  [mk_string => ["Z3_context", "Z3_string"] => "Z3_ast"],
  [is_string => ["Z3_context", "Z3_ast"] => "bool"],
  [get_string => ["Z3_context", "Z3_ast"] => "Z3_string"],
  [mk_seq_empty => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_seq_unit => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_seq_concat => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_seq_prefix => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_suffix => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_contains => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_extract => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_replace => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_at => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_seq_length => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_seq_index => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_str_to_int => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_int_to_str => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_seq_to_re => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_seq_in_re => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_re_plus => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_re_star => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_re_option => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_re_union => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_re_concat => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_re_range => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_re_loop => ["Z3_context", "Z3_ast", "uint", "uint"] => "Z3_ast"],
  [mk_re_intersect => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [mk_re_complement => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_re_empty => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_re_full => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_pattern => ["Z3_context", "uint", "Z3_ast_arr"] => "Z3_pattern"],
  [mk_bound => ["Z3_context", "uint", "Z3_sort"] => "Z3_ast"],
  [mk_forall => ["Z3_context", "uint", "uint", "Z3_pattern_arr", "uint", "Z3_sort_arr", "Z3_symbol_arr", "Z3_ast"] => "Z3_ast"],
  [mk_exists => ["Z3_context", "uint", "uint", "Z3_pattern_arr", "uint", "Z3_sort_arr", "Z3_symbol_arr", "Z3_ast"] => "Z3_ast"],
  [mk_quantifier => ["Z3_context", "bool", "uint", "uint", "Z3_pattern_arr", "uint", "Z3_sort_arr", "Z3_symbol_arr", "Z3_ast"] => "Z3_ast"],
  [mk_quantifier_ex => ["Z3_context", "bool", "uint", "Z3_symbol", "Z3_symbol", "uint", "Z3_pattern_arr", "uint", "Z3_ast_arr", "uint", "Z3_sort_arr", "Z3_symbol_arr", "Z3_ast"] => "Z3_ast"],
  [mk_forall_const => ["Z3_context", "uint", "uint", "Z3_app_arr", "uint", "Z3_pattern_arr", "Z3_ast"] => "Z3_ast"],
  [mk_exists_const => ["Z3_context", "uint", "uint", "Z3_app_arr", "uint", "Z3_pattern_arr", "Z3_ast"] => "Z3_ast"],
  [mk_quantifier_const => ["Z3_context", "bool", "uint", "uint", "Z3_app_arr", "uint", "Z3_pattern_arr", "Z3_ast"] => "Z3_ast"],
  [mk_quantifier_const_ex => ["Z3_context", "bool", "uint", "Z3_symbol", "Z3_symbol", "uint", "Z3_app_arr", "uint", "Z3_pattern_arr", "uint", "Z3_ast_arr", "Z3_ast"] => "Z3_ast"],
  [mk_lambda => ["Z3_context", "uint", "Z3_sort_arr", "Z3_symbol_arr", "Z3_ast"] => "Z3_ast"],
  [mk_lambda_const => ["Z3_context", "uint", "Z3_app_arr", "Z3_ast"] => "Z3_ast"],
  [get_symbol_kind => ["Z3_context", "Z3_symbol"] => "Z3_symbol_kind"],
  [get_symbol_int => ["Z3_context", "Z3_symbol"] => "int"],
  [get_symbol_string => ["Z3_context", "Z3_symbol"] => "Z3_string"],
  [get_sort_name => ["Z3_context", "Z3_sort"] => "Z3_symbol"],
  [get_sort_id => ["Z3_context", "Z3_sort"] => "uint"],
  [sort_to_ast => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [is_eq_sort => ["Z3_context", "Z3_sort", "Z3_sort"] => "bool"],
  [get_sort_kind => ["Z3_context", "Z3_sort"] => "Z3_sort_kind"],
  [get_bv_sort_size => ["Z3_context", "Z3_sort"] => "uint"],
  [get_finite_domain_sort_size => ["Z3_context", "Z3_sort", "uint64_t*"] => "Z3_bool"],
  [get_array_sort_domain => ["Z3_context", "Z3_sort"] => "Z3_sort"],
  [get_array_sort_range => ["Z3_context", "Z3_sort"] => "Z3_sort"],
  [get_tuple_sort_mk_decl => ["Z3_context", "Z3_sort"] => "Z3_func_decl"],
  [get_tuple_sort_num_fields => ["Z3_context", "Z3_sort"] => "uint"],
  [get_tuple_sort_field_decl => ["Z3_context", "Z3_sort", "uint"] => "Z3_func_decl"],
  [get_datatype_sort_num_constructors => ["Z3_context", "Z3_sort"] => "uint"],
  [get_datatype_sort_constructor => ["Z3_context", "Z3_sort", "uint"] => "Z3_func_decl"],
  [get_datatype_sort_recognizer => ["Z3_context", "Z3_sort", "uint"] => "Z3_func_decl"],
  [get_datatype_sort_constructor_accessor => ["Z3_context", "Z3_sort", "uint", "uint"] => "Z3_func_decl"],
  [datatype_update_field => ["Z3_context", "Z3_func_decl", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [get_relation_arity => ["Z3_context", "Z3_sort"] => "uint"],
  [get_relation_column => ["Z3_context", "Z3_sort", "uint"] => "Z3_sort"],
  [mk_atmost => ["Z3_context", "uint", "Z3_ast_arr", "uint"] => "Z3_ast"],
  [mk_atleast => ["Z3_context", "uint", "Z3_ast_arr", "uint"] => "Z3_ast"],
  [mk_pble => ["Z3_context", "uint", "Z3_ast_arr", "int[]", "int"] => "Z3_ast"],
  [mk_pbge => ["Z3_context", "uint", "Z3_ast_arr", "int[]", "int"] => "Z3_ast"],
  [mk_pbeq => ["Z3_context", "uint", "Z3_ast_arr", "int[]", "int"] => "Z3_ast"],
  [func_decl_to_ast => ["Z3_context", "Z3_func_decl"] => "Z3_ast"],
  [is_eq_func_decl => ["Z3_context", "Z3_func_decl", "Z3_func_decl"] => "bool"],
  [get_func_decl_id => ["Z3_context", "Z3_func_decl"] => "uint"],
  [get_decl_name => ["Z3_context", "Z3_func_decl"] => "Z3_symbol"],
  [get_decl_kind => ["Z3_context", "Z3_func_decl"] => "Z3_decl_kind"],
  [get_domain_size => ["Z3_context", "Z3_func_decl"] => "uint"],
  [get_arity => ["Z3_context", "Z3_func_decl"] => "uint"],
  [get_domain => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_sort"],
  [get_range => ["Z3_context", "Z3_func_decl"] => "Z3_sort"],
  [get_decl_num_parameters => ["Z3_context", "Z3_func_decl"] => "uint"],
  [get_decl_parameter_kind => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_parameter_kind"],
  [get_decl_int_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "int"],
  [get_decl_double_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "double"],
  [get_decl_symbol_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_symbol"],
  [get_decl_sort_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_sort"],
  [get_decl_ast_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_ast"],
  [get_decl_func_decl_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_func_decl"],
  [get_decl_rational_parameter => ["Z3_context", "Z3_func_decl", "uint"] => "Z3_string"],
  [app_to_ast => ["Z3_context", "Z3_app"] => "Z3_ast"],
  [get_app_decl => ["Z3_context", "Z3_app"] => "Z3_func_decl"],
  [get_app_num_args => ["Z3_context", "Z3_app"] => "uint"],
  [get_app_arg => ["Z3_context", "Z3_app", "uint"] => "Z3_ast"],
  [is_eq_ast => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [get_ast_id => ["Z3_context", "Z3_ast"] => "uint"],
  [get_ast_hash => ["Z3_context", "Z3_ast"] => "uint"],
  [get_sort => ["Z3_context", "Z3_ast"] => "Z3_sort"],
  [is_well_sorted => ["Z3_context", "Z3_ast"] => "bool"],
  [get_bool_value => ["Z3_context", "Z3_ast"] => "Z3_lbool"],
  [get_ast_kind => ["Z3_context", "Z3_ast"] => "Z3_ast_kind"],
  [is_app => ["Z3_context", "Z3_ast"] => "bool"],
  [is_numeral_ast => ["Z3_context", "Z3_ast"] => "bool"],
  [is_algebraic_number => ["Z3_context", "Z3_ast"] => "bool"],
  [to_app => ["Z3_context", "Z3_ast"] => "Z3_app"],
  [to_func_decl => ["Z3_context", "Z3_ast"] => "Z3_func_decl"],
  [get_numeral_string => ["Z3_context", "Z3_ast"] => "Z3_string"],
  [get_numeral_decimal_string => ["Z3_context", "Z3_ast", "uint"] => "Z3_string"],
  [get_numeral_double => ["Z3_context", "Z3_ast"] => "double"],
  [get_numerator => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [get_denominator => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [get_numeral_small => ["Z3_context", "Z3_ast", "int64_t*", "int64_t*"] => "bool"],
  [get_numeral_int => ["Z3_context", "Z3_ast", "int*"] => "bool"],
  [get_numeral_uint => ["Z3_context", "Z3_ast", "uint*"] => "bool"],
  [get_numeral_uint64 => ["Z3_context", "Z3_ast", "uint64_t*"] => "bool"],
  [get_numeral_int64 => ["Z3_context", "Z3_ast", "int64_t*"] => "bool"],
  [get_numeral_rational_int64 => ["Z3_context", "Z3_ast", "int64_t*", "int64_t*"] => "bool"],
  [get_algebraic_number_lower => ["Z3_context", "Z3_ast", "uint"] => "Z3_ast"],
  [get_algebraic_number_upper => ["Z3_context", "Z3_ast", "uint"] => "Z3_ast"],
  [pattern_to_ast => ["Z3_context", "Z3_pattern"] => "Z3_ast"],
  [get_pattern_num_terms => ["Z3_context", "Z3_pattern"] => "uint"],
  [get_pattern => ["Z3_context", "Z3_pattern", "uint"] => "Z3_ast"],
  [get_index_value => ["Z3_context", "Z3_ast"] => "uint"],
  [is_quantifier_forall => ["Z3_context", "Z3_ast"] => "bool"],
  [is_quantifier_exists => ["Z3_context", "Z3_ast"] => "bool"],
  [is_lambda => ["Z3_context", "Z3_ast"] => "bool"],
  [get_quantifier_weight => ["Z3_context", "Z3_ast"] => "uint"],
  [get_quantifier_num_patterns => ["Z3_context", "Z3_ast"] => "uint"],
  [get_quantifier_pattern_ast => ["Z3_context", "Z3_ast", "uint"] => "Z3_pattern"],
  [get_quantifier_num_no_patterns => ["Z3_context", "Z3_ast"] => "uint"],
  [get_quantifier_no_pattern_ast => ["Z3_context", "Z3_ast", "uint"] => "Z3_ast"],
  [get_quantifier_num_bound => ["Z3_context", "Z3_ast"] => "uint"],
  [get_quantifier_bound_name => ["Z3_context", "Z3_ast", "uint"] => "Z3_symbol"],
  [get_quantifier_bound_sort => ["Z3_context", "Z3_ast", "uint"] => "Z3_sort"],
  [get_quantifier_body => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [simplify => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [simplify_ex => ["Z3_context", "Z3_ast", "Z3_params"] => "Z3_ast"],
  [simplify_get_help => ["Z3_context"] => "Z3_string"],
  [simplify_get_param_descrs => ["Z3_context"] => "Z3_param_descrs"],
  [update_term => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [substitute => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr", "Z3_ast_arr"] => "Z3_ast"],
  [substitute_vars => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr"] => "Z3_ast"],
  [translate => ["Z3_context", "Z3_ast", "Z3_context"] => "Z3_ast"],
  [mk_model => ["Z3_context"] => "Z3_model"],
  [model_inc_ref => ["Z3_context", "Z3_model"] => "void"],
  [model_dec_ref => ["Z3_context", "Z3_model"] => "void"],
  [model_eval => ["Z3_context", "Z3_model", "Z3_ast", "bool", "Z3_ast_ptr"] => "Z3_bool", sub {
    my ($xsub, $ctx, $model, $ast, $completion, $val) = @_;
    die "\$val needs to be passed as a scalar reference to model_eval" unless ref($val) eq 'SCALAR';

    my $ret = $xsub->($ctx, $model, $ast, $completion, $val);
    my $pointer = $$val;
    # rebless the inner object into the right type for later
    $$val = bless \$pointer, "Z3::FFI::Types::Z3_ast";

    return $ret;
  }],
  [model_get_const_interp => ["Z3_context", "Z3_model", "Z3_func_decl"] => "Z3_ast"],
  [model_has_interp => ["Z3_context", "Z3_model", "Z3_func_decl"] => "bool"],
  [model_get_func_interp => ["Z3_context", "Z3_model", "Z3_func_decl"] => "Z3_func_interp"],
  [model_get_num_consts => ["Z3_context", "Z3_model"] => "uint"],
  [model_get_const_decl => ["Z3_context", "Z3_model", "uint"] => "Z3_func_decl"],
  [model_get_num_funcs => ["Z3_context", "Z3_model"] => "uint"],
  [model_get_func_decl => ["Z3_context", "Z3_model", "uint"] => "Z3_func_decl"],
  [model_get_num_sorts => ["Z3_context", "Z3_model"] => "uint"],
  [model_get_sort => ["Z3_context", "Z3_model", "uint"] => "Z3_sort"],
  [model_get_sort_universe => ["Z3_context", "Z3_model", "Z3_sort"] => "Z3_ast_vector"],
  [model_translate => ["Z3_context", "Z3_model", "Z3_context"] => "Z3_model"],
  [is_as_array => ["Z3_context", "Z3_ast"] => "bool"],
  [get_as_array_func_decl => ["Z3_context", "Z3_ast"] => "Z3_func_decl"],
  [add_func_interp => ["Z3_context", "Z3_model", "Z3_func_decl", "Z3_ast"] => "Z3_func_interp"],
  [add_const_interp => ["Z3_context", "Z3_model", "Z3_func_decl", "Z3_ast"] => "void"],
  [func_interp_inc_ref => ["Z3_context", "Z3_func_interp"] => "void"],
  [func_interp_dec_ref => ["Z3_context", "Z3_func_interp"] => "void"],
  [func_interp_get_num_entries => ["Z3_context", "Z3_func_interp"] => "uint"],
  [func_interp_get_entry => ["Z3_context", "Z3_func_interp", "uint"] => "Z3_func_entry"],
  [func_interp_get_else => ["Z3_context", "Z3_func_interp"] => "Z3_ast"],
  [func_interp_set_else => ["Z3_context", "Z3_func_interp", "Z3_ast"] => "void"],
  [func_interp_get_arity => ["Z3_context", "Z3_func_interp"] => "uint"],
  [func_interp_add_entry => ["Z3_context", "Z3_func_interp", "Z3_ast_vector", "Z3_ast"] => "void"],
  [func_entry_inc_ref => ["Z3_context", "Z3_func_entry"] => "void"],
  [func_entry_dec_ref => ["Z3_context", "Z3_func_entry"] => "void"],
  [func_entry_get_value => ["Z3_context", "Z3_func_entry"] => "Z3_ast"],
  [func_entry_get_num_args => ["Z3_context", "Z3_func_entry"] => "uint"],
  [func_entry_get_arg => ["Z3_context", "Z3_func_entry", "uint"] => "Z3_ast"],
  [open_log => ["Z3_string"] => "bool"],
  [append_log => ["Z3_string"] => "void"],
  [close_log => [] => "void"],
  [toggle_warning_messages => ["bool"] => "void"],
  [set_ast_print_mode => ["Z3_context", "Z3_ast_print_mode"] => "void"],
  [ast_to_string => ["Z3_context", "Z3_ast"] => "Z3_string"],
  [pattern_to_string => ["Z3_context", "Z3_pattern"] => "Z3_string"],
  [sort_to_string => ["Z3_context", "Z3_sort"] => "Z3_string"],
  [func_decl_to_string => ["Z3_context", "Z3_func_decl"] => "Z3_string"],
  [model_to_string => ["Z3_context", "Z3_model"] => "Z3_string"],
  [benchmark_to_smtlib_string => ["Z3_context", "Z3_string", "Z3_string", "Z3_string", "Z3_string", "uint", "Z3_ast_arr", "Z3_ast"] => "Z3_string"],
  [parse_smtlib2_string => ["Z3_context", "Z3_string", "uint", "Z3_symbol_arr", "Z3_sort_arr", "uint", "Z3_symbol_arr", "Z3_func_decl_arr"] => "Z3_ast_vector"],
  [parse_smtlib2_file => ["Z3_context", "Z3_string", "uint", "Z3_symbol_arr", "Z3_sort_arr", "uint", "Z3_symbol_arr", "Z3_func_decl_arr"] => "Z3_ast_vector"],
  [eval_smtlib2_string => ["Z3_context", "Z3_string"] => "Z3_string"],
  [get_error_code => ["Z3_context"] => "Z3_error_code"],
  [set_error_handler => ["Z3_context", "Z3_error_handler"] => "void", sub {
    my ($xsub, $ctx, $sub) = @_;
    die "\$sub needs to be a coderef when passed to set_error_handler" unless ref($sub) eq 'CODE';

    # extra level, but so we can wrap the arguments properly
    my $closure = $ffi->closure(sub {
      my ($ctx_ptr, $err_ptr) = @_;
      my $ctx = bless \$ctx_ptr, 'Z3::FFI::Types::Z3_context';
      my $err = bless \$err_ptr, 'Z3::FFI::Types::Z3_error_code';
      $sub->($ctx, $err);
    });
    $xsub->($ctx, $closure);
  }],
  [set_error => ["Z3_context", "Z3_error_code"] => "void"],
  [get_error_msg => ["Z3_context", "Z3_error_code"] => "Z3_string"],
  [get_version => ["uint *", "uint *", "uint *", "uint *"] => "void"],
  [get_full_version => [] => "Z3_string"],
  [enable_trace => ["Z3_string"] => "void"],
  [disable_trace => ["Z3_string"] => "void"],
  [reset_memory => [] => "void"],
  [finalize_memory => [] => "void"],
  [mk_goal => ["Z3_context", "bool", "bool", "bool"] => "Z3_goal"],
  [goal_inc_ref => ["Z3_context", "Z3_goal"] => "void"],
  [goal_dec_ref => ["Z3_context", "Z3_goal"] => "void"],
  [goal_precision => ["Z3_context", "Z3_goal"] => "Z3_goal_prec"],
  [goal_assert => ["Z3_context", "Z3_goal", "Z3_ast"] => "void"],
  [goal_inconsistent => ["Z3_context", "Z3_goal"] => "bool"],
  [goal_depth => ["Z3_context", "Z3_goal"] => "uint"],
  [goal_reset => ["Z3_context", "Z3_goal"] => "void"],
  [goal_size => ["Z3_context", "Z3_goal"] => "uint"],
  [goal_formula => ["Z3_context", "Z3_goal", "uint"] => "Z3_ast"],
  [goal_num_exprs => ["Z3_context", "Z3_goal"] => "uint"],
  [goal_is_decided_sat => ["Z3_context", "Z3_goal"] => "bool"],
  [goal_is_decided_unsat => ["Z3_context", "Z3_goal"] => "bool"],
  [goal_translate => ["Z3_context", "Z3_goal", "Z3_context"] => "Z3_goal"],
  [goal_convert_model => ["Z3_context", "Z3_goal", "Z3_model"] => "Z3_model"],
  [goal_to_string => ["Z3_context", "Z3_goal"] => "Z3_string"],
  [goal_to_dimacs_string => ["Z3_context", "Z3_goal"] => "Z3_string"],
  [mk_tactic => ["Z3_context", "Z3_string"] => "Z3_tactic"],
  [tactic_inc_ref => ["Z3_context", "Z3_tactic"] => "void"],
  [tactic_dec_ref => ["Z3_context", "Z3_tactic"] => "void"],
  [mk_probe => ["Z3_context", "Z3_string"] => "Z3_probe"],
  [probe_inc_ref => ["Z3_context", "Z3_probe"] => "void"],
  [probe_dec_ref => ["Z3_context", "Z3_probe"] => "void"],
  [tactic_and_then => ["Z3_context", "Z3_tactic", "Z3_tactic"] => "Z3_tactic"],
  [tactic_or_else => ["Z3_context", "Z3_tactic", "Z3_tactic"] => "Z3_tactic"],
  [tactic_par_or => ["Z3_context", "uint", "Z3_tactic_arr"] => "Z3_tactic"],
  [tactic_par_and_then => ["Z3_context", "Z3_tactic", "Z3_tactic"] => "Z3_tactic"],
  [tactic_try_for => ["Z3_context", "Z3_tactic", "uint"] => "Z3_tactic"],
  [tactic_when => ["Z3_context", "Z3_probe", "Z3_tactic"] => "Z3_tactic"],
  [tactic_cond => ["Z3_context", "Z3_probe", "Z3_tactic", "Z3_tactic"] => "Z3_tactic"],
  [tactic_repeat => ["Z3_context", "Z3_tactic", "uint"] => "Z3_tactic"],
  [tactic_skip => ["Z3_context"] => "Z3_tactic"],
  [tactic_fail => ["Z3_context"] => "Z3_tactic"],
  [tactic_fail_if => ["Z3_context", "Z3_probe"] => "Z3_tactic"],
  [tactic_fail_if_not_decided => ["Z3_context"] => "Z3_tactic"],
  [tactic_using_params => ["Z3_context", "Z3_tactic", "Z3_params"] => "Z3_tactic"],
  [probe_const => ["Z3_context", "double"] => "Z3_probe"],
  [probe_lt => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_gt => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_le => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_ge => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_eq => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_and => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_or => ["Z3_context", "Z3_probe", "Z3_probe"] => "Z3_probe"],
  [probe_not => ["Z3_context", "Z3_probe"] => "Z3_probe"],
  [get_num_tactics => ["Z3_context"] => "uint"],
  [get_tactic_name => ["Z3_context", "uint"] => "Z3_string"],
  [get_num_probes => ["Z3_context"] => "uint"],
  [get_probe_name => ["Z3_context", "uint"] => "Z3_string"],
  [tactic_get_help => ["Z3_context", "Z3_tactic"] => "Z3_string"],
  [tactic_get_param_descrs => ["Z3_context", "Z3_tactic"] => "Z3_param_descrs"],
  [tactic_get_descr => ["Z3_context", "Z3_string"] => "Z3_string"],
  [probe_get_descr => ["Z3_context", "Z3_string"] => "Z3_string"],
  [probe_apply => ["Z3_context", "Z3_probe", "Z3_goal"] => "double"],
  [tactic_apply => ["Z3_context", "Z3_tactic", "Z3_goal"] => "Z3_apply_result"],
  [tactic_apply_ex => ["Z3_context", "Z3_tactic", "Z3_goal", "Z3_params"] => "Z3_apply_result"],
  [apply_result_inc_ref => ["Z3_context", "Z3_apply_result"] => "void"],
  [apply_result_dec_ref => ["Z3_context", "Z3_apply_result"] => "void"],
  [apply_result_to_string => ["Z3_context", "Z3_apply_result"] => "Z3_string"],
  [apply_result_get_num_subgoals => ["Z3_context", "Z3_apply_result"] => "uint"],
  [apply_result_get_subgoal => ["Z3_context", "Z3_apply_result", "uint"] => "Z3_goal"],
  [mk_solver => ["Z3_context"] => "Z3_solver"],
  [mk_simple_solver => ["Z3_context"] => "Z3_solver"],
  [mk_solver_for_logic => ["Z3_context", "Z3_symbol"] => "Z3_solver"],
  [mk_solver_from_tactic => ["Z3_context", "Z3_tactic"] => "Z3_solver"],
  [solver_translate => ["Z3_context", "Z3_solver", "Z3_context"] => "Z3_solver"],
  [solver_import_model_converter => ["Z3_context", "Z3_solver", "Z3_solver"] => "void"],
  [solver_get_help => ["Z3_context", "Z3_solver"] => "Z3_string"],
  [solver_get_param_descrs => ["Z3_context", "Z3_solver"] => "Z3_param_descrs"],
  [solver_set_params => ["Z3_context", "Z3_solver", "Z3_params"] => "void"],
  [solver_inc_ref => ["Z3_context", "Z3_solver"] => "void"],
  [solver_dec_ref => ["Z3_context", "Z3_solver"] => "void"],
  [solver_push => ["Z3_context", "Z3_solver"] => "void"],
  [solver_pop => ["Z3_context", "Z3_solver", "uint"] => "void"],
  [solver_reset => ["Z3_context", "Z3_solver"] => "void"],
  [solver_get_num_scopes => ["Z3_context", "Z3_solver"] => "uint"],
  [solver_assert => ["Z3_context", "Z3_solver", "Z3_ast"] => "void"],
  [solver_assert_and_track => ["Z3_context", "Z3_solver", "Z3_ast", "Z3_ast"] => "void"],
  [solver_from_file => ["Z3_context", "Z3_solver", "Z3_string"] => "void"],
  [solver_from_string => ["Z3_context", "Z3_solver", "Z3_string"] => "void"],
  [solver_get_assertions => ["Z3_context", "Z3_solver"] => "Z3_ast_vector"],
  [solver_get_units => ["Z3_context", "Z3_solver"] => "Z3_ast_vector"],
  [solver_get_non_units => ["Z3_context", "Z3_solver"] => "Z3_ast_vector"],
  [solver_check => ["Z3_context", "Z3_solver"] => "Z3_lbool"],
  [solver_check_assumptions => ["Z3_context", "Z3_solver", "uint", "Z3_ast_arr"] => "Z3_lbool"],
  [get_implied_equalities => ["Z3_context", "Z3_solver", "uint", "Z3_ast_arr", "uint[]"] => "Z3_lbool"],
  [solver_get_consequences => ["Z3_context", "Z3_solver", "Z3_ast_vector", "Z3_ast_vector", "Z3_ast_vector"] => "Z3_lbool"],
  [solver_cube => ["Z3_context", "Z3_solver", "Z3_ast_vector", "uint"] => "Z3_ast_vector"],
  [solver_get_model => ["Z3_context", "Z3_solver"] => "Z3_model"],
  [solver_get_proof => ["Z3_context", "Z3_solver"] => "Z3_ast"],
  [solver_get_unsat_core => ["Z3_context", "Z3_solver"] => "Z3_ast_vector"],
  [solver_get_reason_unknown => ["Z3_context", "Z3_solver"] => "Z3_string"],
  [solver_get_statistics => ["Z3_context", "Z3_solver"] => "Z3_stats"],
  [solver_to_string => ["Z3_context", "Z3_solver"] => "Z3_string"],
  [stats_to_string => ["Z3_context", "Z3_stats"] => "Z3_string"],
  [stats_inc_ref => ["Z3_context", "Z3_stats"] => "void"],
  [stats_dec_ref => ["Z3_context", "Z3_stats"] => "void"],
  [stats_size => ["Z3_context", "Z3_stats"] => "uint"],
  [stats_get_key => ["Z3_context", "Z3_stats", "uint"] => "Z3_string"],
  [stats_is_uint => ["Z3_context", "Z3_stats", "uint"] => "bool"],
  [stats_is_double => ["Z3_context", "Z3_stats", "uint"] => "bool"],
  [stats_get_uint_value => ["Z3_context", "Z3_stats", "uint"] => "uint"],
  [stats_get_double_value => ["Z3_context", "Z3_stats", "uint"] => "double"],
  [get_estimated_alloc_size => [] => "uint64_t"],
  [mk_fpa_rounding_mode_sort => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_round_nearest_ties_to_even => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_rne => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_round_nearest_ties_to_away => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_rna => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_round_toward_positive => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_rtp => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_round_toward_negative => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_rtn => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_round_toward_zero => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_rtz => ["Z3_context"] => "Z3_ast"],
  [mk_fpa_sort => ["Z3_context", "uint", "uint"] => "Z3_sort"],
  [mk_fpa_sort_half => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_16 => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_single => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_32 => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_double => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_64 => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_quadruple => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_sort_128 => ["Z3_context"] => "Z3_sort"],
  [mk_fpa_nan => ["Z3_context", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_inf => ["Z3_context", "Z3_sort", "bool"] => "Z3_ast"],
  [mk_fpa_zero => ["Z3_context", "Z3_sort", "bool"] => "Z3_ast"],
  [mk_fpa_fp => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_numeral_float => ["Z3_context", "float", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_numeral_double => ["Z3_context", "double", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_numeral_int => ["Z3_context", "int", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_numeral_int_uint => ["Z3_context", "bool", "int", "uint", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_numeral_int64_uint64 => ["Z3_context", "bool", "int64_t", "uint64_t", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_abs => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_neg => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_add => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_sub => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_mul => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_div => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_fma => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_sqrt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_rem => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_round_to_integral => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_min => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_max => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_leq => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_lt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_geq => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_gt => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_eq => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_normal => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_subnormal => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_zero => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_infinite => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_nan => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_negative => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_is_positive => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_to_fp_bv => ["Z3_context", "Z3_ast", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_to_fp_float => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_to_fp_real => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_sort"] => "Z3_ast"],
  [mk_fpa_to_fp_signed => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_sort"] => "Z3_ast"],
#  [mk_fpa_to_fp_uint => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_sort"] => "Z3_ast"], # TODO not found in library
  [mk_fpa_to_ubv => ["Z3_context", "Z3_ast", "Z3_ast", "uint"] => "Z3_ast"],
  [mk_fpa_to_sbv => ["Z3_context", "Z3_ast", "Z3_ast", "uint"] => "Z3_ast"],
  [mk_fpa_to_real => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [fpa_get_ebits => ["Z3_context", "Z3_sort"] => "uint"],
  [fpa_get_sbits => ["Z3_context", "Z3_sort"] => "uint"],
  [fpa_is_numeral_nan => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_inf => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_zero => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_normal => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_subnormal => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_positive => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_is_numeral_negative => ["Z3_context", "Z3_ast"] => "bool"],
  [fpa_get_numeral_sign_bv => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [fpa_get_numeral_significand_bv => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [fpa_get_numeral_sign => ["Z3_context", "Z3_ast", "int *"] => "bool"],
  [fpa_get_numeral_significand_string => ["Z3_context", "Z3_ast"] => "Z3_string"],
  [fpa_get_numeral_significand_uint64 => ["Z3_context", "Z3_ast", "uint64_t *"] => "bool"],
  [fpa_get_numeral_exponent_string => ["Z3_context", "Z3_ast", "bool"] => "Z3_string"],
  [fpa_get_numeral_exponent_int64 => ["Z3_context", "Z3_ast", "int64_t *", "bool"] => "bool"],
  [fpa_get_numeral_exponent_bv => ["Z3_context", "Z3_ast", "bool"] => "Z3_ast"],
  [mk_fpa_to_ieee_bv => ["Z3_context", "Z3_ast"] => "Z3_ast"],
  [mk_fpa_to_fp_int_real => ["Z3_context", "Z3_ast", "Z3_ast", "Z3_ast", "Z3_sort"] => "Z3_ast"],
  [algebraic_is_value => ["Z3_context", "Z3_ast"] => "bool"],
  [algebraic_is_pos => ["Z3_context", "Z3_ast"] => "bool"],
  [algebraic_is_neg => ["Z3_context", "Z3_ast"] => "bool"],
  [algebraic_is_zero => ["Z3_context", "Z3_ast"] => "bool"],
  [algebraic_sign => ["Z3_context", "Z3_ast"] => "int"],
  [algebraic_add => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [algebraic_sub => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [algebraic_mul => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [algebraic_div => ["Z3_context", "Z3_ast", "Z3_ast"] => "Z3_ast"],
  [algebraic_root => ["Z3_context", "Z3_ast", "uint"] => "Z3_ast"],
  [algebraic_power => ["Z3_context", "Z3_ast", "uint"] => "Z3_ast"],
  [algebraic_lt => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_gt => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_le => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_ge => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_eq => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_neq => ["Z3_context", "Z3_ast", "Z3_ast"] => "bool"],
  [algebraic_roots => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr"] => "Z3_ast_vector"],
  [algebraic_eval => ["Z3_context", "Z3_ast", "uint", "Z3_ast_arr"] => "int"],
  [mk_ast_vector => ["Z3_context"] => "Z3_ast_vector"],
  [ast_vector_inc_ref => ["Z3_context", "Z3_ast_vector"] => "void"],
  [ast_vector_dec_ref => ["Z3_context", "Z3_ast_vector"] => "void"],
  [ast_vector_size => ["Z3_context", "Z3_ast_vector"] => "uint"],
  [ast_vector_get => ["Z3_context", "Z3_ast_vector", "uint"] => "Z3_ast"],
  [ast_vector_set => ["Z3_context", "Z3_ast_vector", "uint", "Z3_ast"] => "void"],
  [ast_vector_resize => ["Z3_context", "Z3_ast_vector", "uint"] => "void"],
  [ast_vector_push => ["Z3_context", "Z3_ast_vector", "Z3_ast"] => "void"],
  [ast_vector_translate => ["Z3_context", "Z3_ast_vector", "Z3_context"] => "Z3_ast_vector"],
  [ast_vector_to_string => ["Z3_context", "Z3_ast_vector"] => "Z3_string"],
  [mk_ast_map => ["Z3_context"] => "Z3_ast_map"],
  [ast_map_inc_ref => ["Z3_context", "Z3_ast_map"] => "void"],
  [ast_map_dec_ref => ["Z3_context", "Z3_ast_map"] => "void"],
  [ast_map_contains => ["Z3_context", "Z3_ast_map", "Z3_ast"] => "bool"],
  [ast_map_find => ["Z3_context", "Z3_ast_map", "Z3_ast"] => "Z3_ast"],
  [ast_map_insert => ["Z3_context", "Z3_ast_map", "Z3_ast", "Z3_ast"] => "void"],
  [ast_map_erase => ["Z3_context", "Z3_ast_map", "Z3_ast"] => "void"],
  [ast_map_reset => ["Z3_context", "Z3_ast_map"] => "void"],
  [ast_map_size => ["Z3_context", "Z3_ast_map"] => "uint"],
  [ast_map_keys => ["Z3_context", "Z3_ast_map"] => "Z3_ast_vector"],
  [ast_map_to_string => ["Z3_context", "Z3_ast_map"] => "Z3_string"],
  [mk_optimize => ["Z3_context"] => "Z3_optimize"],
  [optimize_inc_ref => ["Z3_context", "Z3_optimize"] => "void"],
  [optimize_dec_ref => ["Z3_context", "Z3_optimize"] => "void"],
  [optimize_assert => ["Z3_context", "Z3_optimize", "Z3_ast"] => "void"],
  [optimize_assert_soft => ["Z3_context", "Z3_optimize", "Z3_ast", "Z3_string", "Z3_symbol"] => "uint"],
  [optimize_maximize => ["Z3_context", "Z3_optimize", "Z3_ast"] => "uint"],
  [optimize_minimize => ["Z3_context", "Z3_optimize", "Z3_ast"] => "uint"],
  [optimize_push => ["Z3_context", "Z3_optimize"] => "void"],
  [optimize_pop => ["Z3_context", "Z3_optimize"] => "void"],
  [optimize_check => ["Z3_context", "Z3_optimize", "uint", "Z3_ast_arr"] => "Z3_lbool"],
  [optimize_get_reason_unknown => ["Z3_context", "Z3_optimize"] => "Z3_string"],
  [optimize_get_model => ["Z3_context", "Z3_optimize"] => "Z3_model"],
  [optimize_get_unsat_core => ["Z3_context", "Z3_optimize"] => "Z3_ast_vector"],
  [optimize_set_params => ["Z3_context", "Z3_optimize", "Z3_params"] => "void"],
  [optimize_get_param_descrs => ["Z3_context", "Z3_optimize"] => "Z3_param_descrs"],
  [optimize_get_lower => ["Z3_context", "Z3_optimize", "uint"] => "Z3_ast"],
  [optimize_get_upper => ["Z3_context", "Z3_optimize", "uint"] => "Z3_ast"],
  [optimize_get_lower_as_vector => ["Z3_context", "Z3_optimize", "uint"] => "Z3_ast_vector"],
  [optimize_get_upper_as_vector => ["Z3_context", "Z3_optimize", "uint"] => "Z3_ast_vector"],
  [optimize_to_string => ["Z3_context", "Z3_optimize"] => "Z3_string"],
  [optimize_from_string => ["Z3_context", "Z3_optimize", "Z3_string"] => "void"],
  [optimize_from_file => ["Z3_context", "Z3_optimize", "Z3_string"] => "void"],
  [optimize_get_help => ["Z3_context", "Z3_optimize"] => "Z3_string"],
  [optimize_get_statistics => ["Z3_context", "Z3_optimize"] => "Z3_stats"],
  [optimize_get_assertions => ["Z3_context", "Z3_optimize"] => "Z3_ast_vector"],
  [optimize_get_objectives => ["Z3_context", "Z3_optimize"] => "Z3_ast_vector"],
  [rcf_del => ["Z3_context", "Z3_rcf_num"] => "void"],
  [rcf_mk_rational => ["Z3_context", "Z3_string"] => "Z3_rcf_num"],
  [rcf_mk_small_int => ["Z3_context", "int"] => "Z3_rcf_num"],
  [rcf_mk_pi => ["Z3_context"] => "Z3_rcf_num"],
  [rcf_mk_e => ["Z3_context"] => "Z3_rcf_num"],
  [rcf_mk_infinitesimal => ["Z3_context"] => "Z3_rcf_num"],
  [rcf_mk_roots => ["Z3_context", "uint", "Z3_rcf_num_arr", "Z3_rcf_num_arr"] => "uint"],
  [rcf_add => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_sub => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_mul => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_div => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_neg => ["Z3_context", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_inv => ["Z3_context", "Z3_rcf_num"] => "Z3_rcf_num"],
  [rcf_power => ["Z3_context", "Z3_rcf_num", "uint"] => "Z3_rcf_num"],
  [rcf_lt => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_gt => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_le => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_ge => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_eq => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_neq => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num"] => "bool"],
  [rcf_num_to_string => ["Z3_context", "Z3_rcf_num", "bool", "bool"] => "Z3_string"],
  [rcf_num_to_decimal_string => ["Z3_context", "Z3_rcf_num", "uint"] => "Z3_string"],
  [rcf_get_numerator_denominator => ["Z3_context", "Z3_rcf_num", "Z3_rcf_num_ptr", "Z3_rcf_num_ptr"] => "void", sub {
    my ($xsub, $ctx, $in, $num, $denom) = @_;
    die "\$num needs to be passed as a scalar reference to rcf_get_numerator_denominator" unless ref($num) eq 'SCALAR';
    die "\$denom needs to be passed as a scalar reference to rcf_get_numerator_denominator" unless ref($denom) eq 'SCALAR';

    my $ret = $xsub->($ctx, $in, $num, $denom);
    my $pointer = $$num;
    my $pointer2 = $$denom;
    # rebless the inner object into the right type for later
    $$num = bless \$pointer, "Z3::FFI::Types::Z3_rcf_num";
    $$denom = bless \$pointer2, "Z3::FFI::Types::Z3_rcf_num";
    
    return $ret;
    }],
];

my $real_types = {
  Z3_bool => 'bool',
  Z3_lbool => 'int',
  Z3_parameter_kind => 'int',
  Z3_symbol_kind => 'int',
  Z3_sort_kind => 'int',
  Z3_ast_kind => 'int',
  Z3_decl_kind => 'int',
  Z3_param_kind => 'int',
  Z3_ast_print_mode => 'int',
  Z3_error_code => 'int',
  Z3_goal_prec => 'int',
  Z3_string => 'string',
  Z3_string_ptr => 'string *',
  Z3_error_handler => '(opaque, opaque)->void',
};

for my $type (@$opaque_types) {
#  print "Makeint type $type\n";
  $ffi->custom_type($type => {
    native_type => 'opaque',
    native_to_perl => sub {
      my $class = "Z3::FFI::Types::$type";
#      print $class, "\n";
      bless \$_[0], $class;
    },
    perl_to_native => sub {
      my $val = shift;
      die "Wrong type passed, ".ref($val)." expected Z3::FFI::Types::$type" unless ref($val) eq "Z3::FFI::Types::$type";

      return $$val
  }});

  $ffi->load_custom_type("Z3::FFI::ArrayType" => $type."_arr", $type);

  $ffi->type("opaque*" => $type."_ptr");
}
  

for my $type_name (keys %$real_types) {
  my $real_type = $real_types->{$type_name};
  $ffi->type($real_type => $type_name);
}

for my $function (@$functions) {
  my $name = shift @$function;
  $ffi->attach(["Z3_$name" => $name], @$function);
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Z3::FFI - Low level FFI interfaces to the Z3 solver/prover

=head1 VERSION

This is built for Z3 version 4.8.4

=head1 DESCRIPTION

This is a direct translation of the Z3 C API to a Perl API.  It's most likely not the level for working with Z3 from perl.

This is a mostly functional implementation right now.   Three functions related to fixed point math are unimplemented currently.

It should work for any examples from the C API in Z3.

=head1 USE

You're going to want to refer to the C API documentation for Z3, L<http://z3prover.github.io/api/html/group__capi.html>.  
All functions have the Z3_ stripped from their name and are declared as part of this module.

    use Z3::FFI;

    my $config = Z3::FFI::mk_config(); # Create a Z3 config object
    my $context = Z3::FFI::mk_context($config); # Create the Z3 Context object
    ... # work with the Z3 context

This is a nearly complete and direct translation of the Z3 C API to Perl.  All the sames kinds of semantics of the C API regarding ownership and allocation will apply.
You likely don't want to use this library directly, but instead wait for the higher level version wrapper of this API to get finished, which will roughly match the Python
API that already exists.

For some good examples of how to actually use this library, see the t/ directory in the distrobution.

=head1 LICENSE

The bindings themselves are distributed under the Artistic 2.0 license.  However the tests and related 
helper library are based heavily on a translation of the z3 C API examples, which are distrubed by Microsoft
under the MIT license.  As such the code under t/ is distributed under the MIT license also.

    Copyright 2019 Ryan Voots

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

I will also state that I am not entirely sure if it should be me or Microsoft on the above notice for the files under t/, as they are rewritten to work with the Z3::FFI bindings in a new language with additional checks and functionality rather than the original C code.

=head1 TODO

=over 1

=item More testing, from the C API example files

=back

=head1 EXPECTED ISSUES

=over 1

=item Memory leaks.  Due to the differing levels of the APIs and languages, I strongly suspect that there's going to be some memory leaks somewhere.  I'll try to fix these as they're found, but they are not a priority at the moment.

=back

=head1 SEE ALSO

L<Alien::Z3>

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=cut

