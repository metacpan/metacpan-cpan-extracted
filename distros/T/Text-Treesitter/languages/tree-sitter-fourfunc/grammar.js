// A grammar for a tiny four-function numerical expression language

const ADDOP = choice('+', '-');

const MULOP = choice('*', '/');

module.exports = grammar({
  name: "fourfunc",

  extras: $ => [
    /\s+/,
  ],

  rules: {
    fourfunc: ($) => $._expr,

    _expr: ($) => choice(
      seq('(', $._expr, ')'),
      $.number,
      prec.left(2, seq($._expr, MULOP, $._expr)),
      prec.left(1, seq($._expr, ADDOP, $._expr)),
    ),

    number: ($) => /[0-9]+(?:\.[0-9]+)?/,
  },
});
