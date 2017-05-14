.# included from 7_condDir_8.input
This is 7_condDir_8.inc
.let a0 := _ARGS[0]; na := count(_ARGS)
.echo _ARGS[0] = \v{a0} na = \v{na}  incCnt = \v{incCnt}
.#
.# Useful in a straight .if
.if a0 > 0
.return a0
.fi
.#
.# Now decrement incCnt and return that
.return --incCnt
