#include <tree_sitter/parser.h>

#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define LANGUAGE_VERSION 14
#define STATE_COUNT 12
#define LARGE_STATE_COUNT 5
#define SYMBOL_COUNT 11
#define ALIAS_COUNT 0
#define TOKEN_COUNT 8
#define EXTERNAL_TOKEN_COUNT 0
#define FIELD_COUNT 1
#define MAX_ALIAS_SEQUENCE_LENGTH 3
#define PRODUCTION_ID_COUNT 2

enum {
  anon_sym_LPAREN = 1,
  anon_sym_RPAREN = 2,
  anon_sym_STAR = 3,
  anon_sym_SLASH = 4,
  anon_sym_PLUS = 5,
  anon_sym_DASH = 6,
  sym_number = 7,
  sym_fourfunc = 8,
  sym__expr = 9,
  sym_expr = 10,
};

static const char * const ts_symbol_names[] = {
  [ts_builtin_sym_end] = "end",
  [anon_sym_LPAREN] = "(",
  [anon_sym_RPAREN] = ")",
  [anon_sym_STAR] = "*",
  [anon_sym_SLASH] = "/",
  [anon_sym_PLUS] = "+",
  [anon_sym_DASH] = "-",
  [sym_number] = "number",
  [sym_fourfunc] = "fourfunc",
  [sym__expr] = "_expr",
  [sym_expr] = "expr",
};

static const TSSymbol ts_symbol_map[] = {
  [ts_builtin_sym_end] = ts_builtin_sym_end,
  [anon_sym_LPAREN] = anon_sym_LPAREN,
  [anon_sym_RPAREN] = anon_sym_RPAREN,
  [anon_sym_STAR] = anon_sym_STAR,
  [anon_sym_SLASH] = anon_sym_SLASH,
  [anon_sym_PLUS] = anon_sym_PLUS,
  [anon_sym_DASH] = anon_sym_DASH,
  [sym_number] = sym_number,
  [sym_fourfunc] = sym_fourfunc,
  [sym__expr] = sym__expr,
  [sym_expr] = sym_expr,
};

static const TSSymbolMetadata ts_symbol_metadata[] = {
  [ts_builtin_sym_end] = {
    .visible = false,
    .named = true,
  },
  [anon_sym_LPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_RPAREN] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_STAR] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_SLASH] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_PLUS] = {
    .visible = true,
    .named = false,
  },
  [anon_sym_DASH] = {
    .visible = true,
    .named = false,
  },
  [sym_number] = {
    .visible = true,
    .named = true,
  },
  [sym_fourfunc] = {
    .visible = true,
    .named = true,
  },
  [sym__expr] = {
    .visible = false,
    .named = true,
  },
  [sym_expr] = {
    .visible = true,
    .named = true,
  },
};

enum {
  field_operator = 1,
};

static const char * const ts_field_names[] = {
  [0] = NULL,
  [field_operator] = "operator",
};

static const TSFieldMapSlice ts_field_map_slices[PRODUCTION_ID_COUNT] = {
  [1] = {.index = 0, .length = 1},
};

static const TSFieldMapEntry ts_field_map_entries[] = {
  [0] =
    {field_operator, 1},
};

static const TSSymbol ts_alias_sequences[PRODUCTION_ID_COUNT][MAX_ALIAS_SEQUENCE_LENGTH] = {
  [0] = {0},
};

static const uint16_t ts_non_terminal_alias_map[] = {
  0,
};

static const TSStateId ts_primary_state_ids[STATE_COUNT] = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
};

static bool ts_lex(TSLexer *lexer, TSStateId state) {
  START_LEXER();
  eof = lexer->eof(lexer);
  switch (state) {
    case 0:
      if (eof) ADVANCE(2);
      if (lookahead == '(') ADVANCE(3);
      if (lookahead == ')') ADVANCE(4);
      if (lookahead == '*') ADVANCE(5);
      if (lookahead == '+') ADVANCE(7);
      if (lookahead == '-') ADVANCE(8);
      if (lookahead == '/') ADVANCE(6);
      if (lookahead == '\t' ||
          lookahead == '\n' ||
          lookahead == '\r' ||
          lookahead == ' ') SKIP(0)
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(9);
      END_STATE();
    case 1:
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(10);
      END_STATE();
    case 2:
      ACCEPT_TOKEN(ts_builtin_sym_end);
      END_STATE();
    case 3:
      ACCEPT_TOKEN(anon_sym_LPAREN);
      END_STATE();
    case 4:
      ACCEPT_TOKEN(anon_sym_RPAREN);
      END_STATE();
    case 5:
      ACCEPT_TOKEN(anon_sym_STAR);
      END_STATE();
    case 6:
      ACCEPT_TOKEN(anon_sym_SLASH);
      END_STATE();
    case 7:
      ACCEPT_TOKEN(anon_sym_PLUS);
      END_STATE();
    case 8:
      ACCEPT_TOKEN(anon_sym_DASH);
      END_STATE();
    case 9:
      ACCEPT_TOKEN(sym_number);
      if (lookahead == '.') ADVANCE(1);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(9);
      END_STATE();
    case 10:
      ACCEPT_TOKEN(sym_number);
      if (('0' <= lookahead && lookahead <= '9')) ADVANCE(10);
      END_STATE();
    default:
      return false;
  }
}

static const TSLexMode ts_lex_modes[STATE_COUNT] = {
  [0] = {.lex_state = 0},
  [1] = {.lex_state = 0},
  [2] = {.lex_state = 0},
  [3] = {.lex_state = 0},
  [4] = {.lex_state = 0},
  [5] = {.lex_state = 0},
  [6] = {.lex_state = 0},
  [7] = {.lex_state = 0},
  [8] = {.lex_state = 0},
  [9] = {.lex_state = 0},
  [10] = {.lex_state = 0},
  [11] = {.lex_state = 0},
};

static const uint16_t ts_parse_table[LARGE_STATE_COUNT][SYMBOL_COUNT] = {
  [0] = {
    [ts_builtin_sym_end] = ACTIONS(1),
    [anon_sym_LPAREN] = ACTIONS(1),
    [anon_sym_RPAREN] = ACTIONS(1),
    [anon_sym_STAR] = ACTIONS(1),
    [anon_sym_SLASH] = ACTIONS(1),
    [anon_sym_PLUS] = ACTIONS(1),
    [anon_sym_DASH] = ACTIONS(1),
    [sym_number] = ACTIONS(1),
  },
  [1] = {
    [sym_fourfunc] = STATE(11),
    [sym__expr] = STATE(8),
    [sym_expr] = STATE(5),
    [anon_sym_LPAREN] = ACTIONS(3),
    [sym_number] = ACTIONS(5),
  },
  [2] = {
    [ts_builtin_sym_end] = ACTIONS(7),
    [anon_sym_RPAREN] = ACTIONS(7),
    [anon_sym_STAR] = ACTIONS(7),
    [anon_sym_SLASH] = ACTIONS(7),
    [anon_sym_PLUS] = ACTIONS(7),
    [anon_sym_DASH] = ACTIONS(7),
  },
  [3] = {
    [ts_builtin_sym_end] = ACTIONS(9),
    [anon_sym_RPAREN] = ACTIONS(9),
    [anon_sym_STAR] = ACTIONS(9),
    [anon_sym_SLASH] = ACTIONS(9),
    [anon_sym_PLUS] = ACTIONS(9),
    [anon_sym_DASH] = ACTIONS(9),
  },
  [4] = {
    [ts_builtin_sym_end] = ACTIONS(9),
    [anon_sym_RPAREN] = ACTIONS(9),
    [anon_sym_STAR] = ACTIONS(11),
    [anon_sym_SLASH] = ACTIONS(11),
    [anon_sym_PLUS] = ACTIONS(9),
    [anon_sym_DASH] = ACTIONS(9),
  },
};

static const uint16_t ts_small_parse_table[] = {
  [0] = 2,
    ACTIONS(13), 1,
      ts_builtin_sym_end,
    ACTIONS(15), 4,
      anon_sym_STAR,
      anon_sym_SLASH,
      anon_sym_PLUS,
      anon_sym_DASH,
  [10] = 3,
    ACTIONS(17), 1,
      anon_sym_RPAREN,
    ACTIONS(11), 2,
      anon_sym_STAR,
      anon_sym_SLASH,
    ACTIONS(19), 2,
      anon_sym_PLUS,
      anon_sym_DASH,
  [22] = 3,
    ACTIONS(3), 1,
      anon_sym_LPAREN,
    ACTIONS(21), 1,
      sym_number,
    STATE(6), 2,
      sym__expr,
      sym_expr,
  [33] = 2,
    ACTIONS(11), 2,
      anon_sym_STAR,
      anon_sym_SLASH,
    ACTIONS(19), 2,
      anon_sym_PLUS,
      anon_sym_DASH,
  [42] = 3,
    ACTIONS(3), 1,
      anon_sym_LPAREN,
    ACTIONS(23), 1,
      sym_number,
    STATE(3), 2,
      sym__expr,
      sym_expr,
  [53] = 3,
    ACTIONS(3), 1,
      anon_sym_LPAREN,
    ACTIONS(25), 1,
      sym_number,
    STATE(4), 2,
      sym__expr,
      sym_expr,
  [64] = 1,
    ACTIONS(27), 1,
      ts_builtin_sym_end,
};

static const uint32_t ts_small_parse_table_map[] = {
  [SMALL_STATE(5)] = 0,
  [SMALL_STATE(6)] = 10,
  [SMALL_STATE(7)] = 22,
  [SMALL_STATE(8)] = 33,
  [SMALL_STATE(9)] = 42,
  [SMALL_STATE(10)] = 53,
  [SMALL_STATE(11)] = 64,
};

static const TSParseActionEntry ts_parse_actions[] = {
  [0] = {.entry = {.count = 0, .reusable = false}},
  [1] = {.entry = {.count = 1, .reusable = false}}, RECOVER(),
  [3] = {.entry = {.count = 1, .reusable = true}}, SHIFT(7),
  [5] = {.entry = {.count = 1, .reusable = true}}, SHIFT(8),
  [7] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__expr, 3),
  [9] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_expr, 3, .production_id = 1),
  [11] = {.entry = {.count = 1, .reusable = true}}, SHIFT(9),
  [13] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym_fourfunc, 1),
  [15] = {.entry = {.count = 1, .reusable = true}}, REDUCE(sym__expr, 1),
  [17] = {.entry = {.count = 1, .reusable = true}}, SHIFT(2),
  [19] = {.entry = {.count = 1, .reusable = true}}, SHIFT(10),
  [21] = {.entry = {.count = 1, .reusable = true}}, SHIFT(6),
  [23] = {.entry = {.count = 1, .reusable = true}}, SHIFT(3),
  [25] = {.entry = {.count = 1, .reusable = true}}, SHIFT(4),
  [27] = {.entry = {.count = 1, .reusable = true}},  ACCEPT_INPUT(),
};

#ifdef __cplusplus
extern "C" {
#endif
#ifdef _WIN32
#define extern __declspec(dllexport)
#endif

extern const TSLanguage *tree_sitter_fourfunc(void) {
  static const TSLanguage language = {
    .version = LANGUAGE_VERSION,
    .symbol_count = SYMBOL_COUNT,
    .alias_count = ALIAS_COUNT,
    .token_count = TOKEN_COUNT,
    .external_token_count = EXTERNAL_TOKEN_COUNT,
    .state_count = STATE_COUNT,
    .large_state_count = LARGE_STATE_COUNT,
    .production_id_count = PRODUCTION_ID_COUNT,
    .field_count = FIELD_COUNT,
    .max_alias_sequence_length = MAX_ALIAS_SEQUENCE_LENGTH,
    .parse_table = &ts_parse_table[0][0],
    .small_parse_table = ts_small_parse_table,
    .small_parse_table_map = ts_small_parse_table_map,
    .parse_actions = ts_parse_actions,
    .symbol_names = ts_symbol_names,
    .field_names = ts_field_names,
    .field_map_slices = ts_field_map_slices,
    .field_map_entries = ts_field_map_entries,
    .symbol_metadata = ts_symbol_metadata,
    .public_symbol_map = ts_symbol_map,
    .alias_map = ts_non_terminal_alias_map,
    .alias_sequences = &ts_alias_sequences[0][0],
    .lex_modes = ts_lex_modes,
    .lex_fn = ts_lex,
    .primary_state_ids = ts_primary_state_ids,
  };
  return &language;
}
#ifdef __cplusplus
}
#endif
