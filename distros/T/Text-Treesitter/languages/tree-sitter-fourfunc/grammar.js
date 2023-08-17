// A grammar for a tiny four-function numerical expression language

const ADDOP = choice('+', '-');

const MULOP = choice('*', '/');

module.exports = grammar({
  name: "fourfunc",

  extras: $ => [
    /\s+/,
  ],

  rules: {
    fourfunc: ($) => $.expr,

    _expr: ($) => choice(
      seq('(', $._expr, ')'),
      $.number,
      $.expr,
    ),

    expr: ($) => choice(
      prec.left(2, seq($._expr, field('operator', MULOP), $._expr)),
      prec.left(1, seq($._expr, field('operator', ADDOP), $._expr)),
    ),

    number: ($) => /[0-9]+(?:\.[0-9]+)?/,
  },
});
