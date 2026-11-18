# JS semantics the port has to map

Every "Upstream" line below was **measured with the oracle** against the pinned
tag, not recalled. When you measure a new one, add it here and as a corpus case.

Status is `decided` (ADR number) or `open` (karr ticket). For an open entry, do
not pick a mapping locally — see the core skill, "Undecided mappings".

## Value kinds — decided, ADR 0001

| Template | Upstream |
|---|---|
| `{{ 1 == 1 }}`, `{{ t }}` (JSON `true`) | `true` |
| `{{ '1' + 1 }}` / `{{ 1 + 1 }}` | `11` / `2` |
| `{{ '3' * '2' }}` / `{{ '5' - 1 }}` | `6` / `4` |
| `{{ 1 == '1' }}` / `{{ 1 === '1' }}` | `true` / `false` |
| `{{ '10' < '9' }}` / `{{ 10 < 9 }}` | `true` / `false` |

Kind comes from `builtin::is_bool` / `builtin::created_as_number`. `==` is JS
loose equality, `===` strict; both are Runtime calls, never Perl's `==`/`eq`.

## Truthiness — decided by ADR 0001's kinds, mechanism in Runtime

Falsy in JS: `false`, `0`, `NaN`, `''`, `null`, `undefined`. **Truthy** where
Perl disagrees: the string `'0'`, an empty array, an empty object.
Measured: `'0'`, `[]`, `{}` → truthy; `0`, `''` → falsy; `{{ z or 'd' }}` with
`z = 0` → `d`; `{{ '0' and 1 }}` → `1` (and/or return the operand, not a bool).

## undefined vs null — decided, ADR 0006

| Template (`n` = JSON null, `u` missing) | Upstream |
|---|---|
| `{{ u }}` / `{{ n }}` | both empty |
| `{{ u is defined }}` / `{{ n is defined }}` | `false` / `true` |
| `{{ n is none }}` / `{{ u is undefined }}` | `true` / `true` |
| `{{ n.foo }}` / `{{ u.foo.bar }}` | both empty, no error |
| `{{ a.b.c }}` with `throwOnUndefined` | error `attempted to output null or undefined value` |

## Object key order — decided, ADR 0011

`{% for k, v in {b:1, a:2} %}` → `b=1;a=2;` (insertion order). `dump` →
`{"b":1,"a":2}`. `dictsort|join(',')` → `a,2,b,1`.

Not pure insertion order (ADR 0011 amendment, k51): own keys enumerate array
indices first, ascending, then the rest in insertion order. `{"b":1, "2":2,
"1":3}` → `1;2;b;` · keys `a 10 9 01 -1 4294967295 4294967294 1.5` →
`9;10;4294967294;a;01;-1;4294967295;1.5;`. An index is the canonical ASCII
decimal of 0 … 4294967294: `0` is one; `00`, `-0`, `+1`, `' 1'`, `1e3`, `0x1`,
`''`, `"1\n"`, `٣`, `1٣` and `4294967296` and above are not. groupby's result
follows it: years `b 2019 a 10 2018 9` → `9|10|2018|2019|b|a|`. A plain caller
hash puts its indices first too and sorts only the rest (maintainer, k51):
`{b, 10, 9, a, 2}` → `2 9 10 a b`. Seam: Lib `keys` →
`_ordinary_own_property_keys` / `_is_array_index`. A caller-supplied
`Hash::Ordered` gets the JS rule too, indices first, then its own insertion
order (ADR 0011 "Caller-supplied ordered hashes", orchestrator call pending
the maintainer's confirmation, k51). Open: a `Tie::IxHash`-tied hash is
sorted like a plain one, its own order is not honoured (k78). A kwargs object
as a value (`u | default(b=1, a=2)`) iterates `b=1;a=2;__keywords=true;`
upstream, nothing in the port (KwArgs is not an object to Lib/member_lookup;
k79). The `loop` object and an import namespace are plain hashes and iterate
key-sorted, not in JS order (k80).

## Numbers — decided, ADR 0007

`1/3` → `0.3333333333333333` · `0.1+0.2` → `0.30000000000000004` · `1e21` →
`1e+21` · `10/4` → `2.5` · `7 // 2` → `3` · `2 ** 0.5` → `1.4142135623730951` ·
`1/0` → `Infinity` · `'a' * 2` → `NaN`.
Filters: `'3.7'|int` → `3` · `'x'|int` → empty · `'3.7abc'|float` → `3.7` ·
`2.5|round` → `3` · `-2.5|round` → `-2` · `[10,9,1]|sort` → `1,9,10` ·
`['b','A','c']|sort` → `A,b,c`.

## Math.round, Math.abs, Math.pow — port as is, mechanism in Lib; pow ties open, k74

`round` is `rounder(val * factor) / factor`, and Math.round is V8's
Float64Round — ceil(x), one less unless ceil(x) − 0.5 ≤ x — never x + 0.5:
`0.49999999999999994|round` → `0` · `4503599627370497|round` (2^52 + 1) →
`4503599627370497` · `-0.51|round` → `-1`. On [-0.5, -0] it gives -0, which
`1 / x` shows: `1 / (-0.5|round)` · `1 / (-0.2|round)` ·
`1 / (-0.5|round(0, 'ceil'))` → `-Infinity`. `abs` is Math.abs, which drops the
sign of zero: `1 / ((-0)|abs)` → `Infinity` (`1 / -0` → `-Infinity`). Math.pow
— `round`'s factor and the `**` operator — is IEEE pow but NaN where C's pow
gives 1: `1 ** (1/0)` · `(-1) ** (1/0)` · `1 ** (-1/0)` · `1 ** ('a' * 1)` →
`NaN`; `('a' * 1) ** 0` → `1` · `2 ** (1/0)` → `Infinity`. Open: V8's pow and glibc's disagree on some
exact-tie integer powers above 2^53 — `942 ** 6` → `698723607368084600`
upstream, `698723607368084500` in the port (k74). Seams: Lib `js_math_round` /
`js_math_ceil` / `js_math_floor` / `js_math_abs` / `js_math_pow`.

## parseInt and parseFloat — port as is, mechanism in Lib

`int` is `parseInt(value, base)`, base 10 unless given. Leading
StrWhiteSpaceChar and one sign go: `'-12px'` behind U+00A0, U+FEFF and a space
→ `-12` · `'+-1'|int('d')` → `d`. The radix goes through ToInt32:
`'11'|int(base=4294967298)` · `(base=-4294967294)` · `(base=2.9)` → `3`, but
`'11'|int('d', 2147483650)` → `d` (wraps negative, so NaN). 0 means 10, or 16
after a `0x` prefix, which radix 16 strips too: `'0x1f'|int(base=0)` /
`(base=16)` → `31` · `'0x1f'|int` and `'0x1f'|int('d', 8)` → `0` ·
`'0x'|int('d', 16)` → `d`. A zero keeps its sign: `1 / ('-0'|int)` →
`-Infinity`. Past 2^53 the spec leaves the value to the implementation. V8
rounds radix 10 and the powers of two correctly, ties to even —
`'9007199254740993'|int` → `9007199254740992`, 2^53 + 1 and 2^53 + 3 spelt in
radix 2 → `9007199254740992` / `9007199254740996` — but folds any other radix in
32-bit chunks, two roundings each, and can miss by an ulp:
`'1200221000112221021220201222011021'|int('d', 3)` → `9455897125430928`
(correctly rounded: `…926`) · `'wgwkw4s440gwg0'|int('d', 36)` →
`5.538717684257602e+21` (`…601e+21`). Seams: Lib `js_parse_int`,
`_js_to_int32`.

`float` is `parseFloat(val)`: the longest StrDecimalLiteral prefix, `Infinity`
spelt case-sensitively — `'Infinityx'|float` → `Infinity` · `'-Infinity'|float`
→ `-Infinity` · `'infinity'|float('nan')` and `'INFINITY'|float('nan')` → `nan`
(the default, as for any NaN) — with no hex and no numeric separator:
`'1e'|float` → `1` · `'.5'|float` → `0.5` · `'0x10'|float` → `0` ·
`'1_000'|float` → `1`; `1 / ('-0'|float)` → `-Infinity`. Seam: Lib
`js_parse_float`.

## Strings are UTF-16 upstream — decided, ADR 0012

On `'héllo😀'`: `length` → `7`, `s.length` → `7`, `s[1]` → `é`, `reverse` →
splits the surrogate pair into two lone surrogates.
On `t = 'a😀b😀c'`: `t.indexOf('b')` → `3` · `t.lastIndexOf('😀', 3)` → `1` ·
`t.split('').length` → `7` · `''.split('')` → `[]` but `''.split(',')` → `['']` ·
`'abc'.substr(0, -1)` → `''` · `'！' < '😀'` → `false` (code units: U+FF01 >
U+D83D) · `{% for c in '😀ab' %}` runs 4 times. Seams: `Lib` `js_*` (ADR 0012).
With `e = '😀ab'`, `e[0]` and `e[1]` are the two lone halves of the pair. Glued
back together by `~`, `+`, `.concat()`, `replace`, Array `join` or the output
buffer they are the pair again: `(e[0] ~ e[1]) == '😀'` and `=== '😀'` →
`true`, `d[e[0] ~ e[1]]` with `d = {'😀': 'hit'}` → `hit`, `{{ e[0] }}{{ e[1] }}`
outputs `😀`. Decided by ADR 0012: every join goes through `Lib`
`js_string_append`, which re-pairs a lone high + lone low surrogate where two
strings meet (and only there), so no string holds a pair as two surrogate
characters and Perl `eq` and hash keys agree with JS.

## Native JS members from templates — decided, ADR 0008

`s.toUpperCase()` works · `arr.join('-')` → `3-1-2` · `arr.length` → `3` ·
`arr.indexOf(1)` → `1`. Calling something missing:
`Error: Unable to call \`undefinedfn\`, which is undefined or falsey`.

## Native calls on the wrong receiver — V8's TypeError, ADR 0010 / 0016, mechanism in Runtime

filters.js calls methods on values it never checked; the text is V8's, built
from the call site, not from the value. Receiver `undefined` / `null`: the read
throws — `undefined|trim` → `TypeError: Cannot read properties of undefined
(reading 'replace')`, `none|trim` → `... of null (reading 'replace')`. Any
other receiver without the method: the call throws `<src>.<name> is not a
function`, `<src>` being upstream's source text of the receiver — `5|lower` →
`TypeError: str.toLowerCase is not a function` · `5|truncate(2)` →
`input.lastIndexOf ...` · `[1]|wordcount` → `str.match ...` · `true|upper` →
`str.toUpperCase ...`; a call inside the receiver prints as `(...)`
(`ret.charAt(0).x()` → `ret.charAt(...).x is not a function`, measured in node).
Seam: Runtime `js_method_call($obj, $src, $name, @args)` and `js_string_this`
(a String method run with an engine regex); the filter passes upstream's
variable as `$src`. The method resolves through the ADR 0008 surface, so a
method missing there throws the same text even where JS has it.

A plain property read (`arr[0]`, `arr.length`, `v[attr]`) throws only on
undefined / null — `u|first` → `TypeError: Cannot read properties of undefined
(reading '0')` — and names the key as V8 prints it, measured with
`[u]|join(',', k)`: a string as is, a number or boolean through ToString
(`1.5` → `'1.5'`, `true` → `'true'`), a dict literal, caller hash or keyword
arguments as `'#<Object>'`; an array, SafeString or regex key drops the
`(reading ...)` clause (`TypeError: Cannot read properties of undefined`), and
so does a plain object with an own `toString` (`{'toString': 1}`,
`toString=1`) or an own `constructor` that is no named function
(`{'constructor': 1}`, a context hash `{"constructor": "x"}`). That is V8's
NoSideEffectsToMaybeString, the rule of the Array sort TypeError below:
`{'constructor': m}`, `m` a macro, reads `'#<macro>'` upstream; the port drops
the clause until a coderef has a name (k88). Anything else is
`member_lookup`. Seam: Runtime `js_member_read` / `_js_read_error` /
`_js_no_side_effects_to_maybe_string`.

copySafeness's `target.toString()` is the same read — `string` is
`r.copySafeness(obj, obj)`: `u|string` → `TypeError: Cannot read properties of
undefined (reading 'toString')` · `none|string` → `... of null (reading
'toString')`; any other target gives its JS ToString: `5|string` → `5` ·
`[1,2]|string` → `1,2` · `true|string` → `true` · `{}|string` →
`[object Object]`. An own `toString` member and a null prototype are k44. Seam:
Runtime `copy_safeness`.

Array `reduce` (sum's `arr.reduce`) is on the ADR 0008 surface: `'abc'|sum` →
`TypeError: arr.reduce is not a function` · `u|sum` → `... of undefined
(reading 'reduce')` · `[].reduce(f)` → `TypeError: Reduce of empty array with
no initial value`. A callbackfn that is not callable is checked first and
shown V8's way (Runtime `_js_not_callable_text`): `undefined` · `object null`
· `boolean true` · `number 1.5` · `number NaN` · `string "x"` (cut to 100 code
units, then `<...>`) · any object `object` — `[].reduce({})` → `TypeError:
object is not a function`.

Array `filter` (the `.filter` of select, reject, selectattr, rejectattr) is on
the surface too. The length is read once and an index the callback removed is
skipped: with `f` popping `a` on each call, `[1,2,3]` filters to `1,2`; with
`f` pushing `9`, `[1,2]` filters to `1,2` and `a` ends `1,2,9,9`. An element
is kept when the result is truthy, and a macro's output is a SafeString, an
object: `[1, 0, '', 2].filter(m)` keeps all four. A callbackfn that is not
callable throws in the reduce form: `[1].filter(5)` → `TypeError: number 5 is
not a function` · `filter(none)` → `object null is not a function` ·
`filter()` → `undefined is not a function`. Seam: Runtime `%ARRAY_METHODS`
`filter`.

lib.map over a non-array walks it as an array-like, `obj[i]` while `i <
obj.length`, through Runtime (`member_lookup`, `op_lt`): `{length: '2', '0':
'x', '1': 'y'}|reverse|join(',')` → `y,x` · length `'1.5'` → `b,a` · a
SafeString has a length but no indices (`abc` from a macro, `|reverse` → `,,`)
· a number or an object without length maps nothing. A numeric length that is
no array length, `{length: 2.5}` or `{length: -1}`, throws `RangeError: Invalid
array length` (`results.length = obj.length`). Seam: Lib `map`.

## The `is` tests and the globals — port as is, mechanism in Runtime

`lower` / `upper` call `value.toLowerCase()` / `toUpperCase()` unchecked, with
the receiver TypeError above: `5 is lower` → `TypeError: value.toLowerCase is
not a function` · `null is lower` → `... of null (reading 'toLowerCase')`. A
SafeString's result is a primitive: `('abc'|safe) is lower` → `false`.
`iterable` is `!!value[Symbol.iterator]`: true for an array, a string and a
SafeString (`m() is iterable` → `true`), false for a number, boolean, object,
regex or function; undefined and null throw `TypeError: undefined is not
iterable (cannot read property Symbol(Symbol.iterator))` / `object null ...`.
`mapping` is `typeof value === 'object'` minus arrays: `r/a/`, a SafeString and
an engine-built object are mappings, a function is not. Seams: Runtime
`js_method_call`, `js_has_symbol_iterator`.

`range` runs JS `<`, `>` and `+=`: `range('3')` → `0,1,2` · `range('3', 5)` →
`["3"]` (`'3' + 1` is `'31'`) · `range(0, 3, '1')` → `[0,"01"]`;
`range('1', '3')` never ends upstream (string `<`). A falsy step is 1, and a
step that is not `> 0` takes the descending loop: `range(0, 3, 'a')` → `[]`.
`cycler()` is a plain object, own keys `current;reset;next;`, dumped
`{"current":null}`. Its methods use `this`, which memberLookup binds to the
cycler on every read, so `{% set n = c.next %}{{ n() }}` moves `c.current`.
Reached through `{% for k, v in c %}` and called bare, the method gets the
Context as `this` upstream and `c.current` stays null; the port's methods close
over their cycler, so it moves. ADR 0009's no-`this` covers user coderefs, not
engine-built methods: this mapping is open, decision k93. Seam: Globals `cycler`.

## Case mapping — port as is, mechanism in Lib; Unicode version open, k64

JS maps by code point with the full default case conversion, SpecialCasing
included: `'ß'|upper` → `SS` · `'ﬁ'|upper` → `FI` · `('İ'|lower).length` → `2`
(`i` + U+0307) · `'ǅ'|lower` / `|upper` → `ǆ` / `Ǆ`. Final_Sigma, which Perl's
`lc` lacks, follows ICU's context test: `'ΑΣ'` → `ας` · `'ΑΣΑ'` → `ασα` ·
`'Α.Σ'` → `α.ς` · `'ΑΣ1'` → `ας1` · `'1Σ'` → `1σ` · `'ʰΣ'` → `ʰσ` (U+02B0 is
cased *and* case-ignorable; ICU counts it ignorable). Perl maps Latin-1 by
Unicode rules only under `unicode_strings`. Seams: Lib `js_to_lower_case` /
`js_to_upper_case`. Open: the oracle's Node 24 uses Unicode 17, Perl 5.40
Unicode 15 — `'ɤ'|upper` → `Ɤ` upstream, `ɤ` in the port (k64).

## GetSubstitution — port as is, mechanism in Lib

A regex `replace` takes `$` patterns in a string replacement:
`'abc'|replace(r/(b)/, '[$1$2$0$01$10]')` → `a[b$2$0bb0]c` ·
`r/b/` with `` [$&][$`][$'][$$][$] `` → `a[b][a][c][$][$]c` · with eleven groups
`[$11|$10|$1|$12|$011|$00|$100]` → `[k|j|a|a2|a1|$00|j0]` (two digits when that
group exists, else one digit and a literal) · `'ab'|replace(r/(a)|(z)/, '[$1|$2]')`
→ `[a|]b` · `$<n>` → the named group, `''` for an unknown name, literal `$<n>`
when the regex has no named group. `` $` `` / `$'` cut at code-unit positions
(ADR 0012). The **filter** with a string `old` inserts `new` literally:
`` 'abc'|replace('b', '[$&$`]') `` → `` a[$&amp;$`]c ``; the native
`'abc'.replace('b', '$&$&')` → `abbc` (k56). Seam: Lib `js_get_substitution`.

## Symbol.replace: empty matches, lastIndex, groups — ADR 0013, mechanism in Runtime

An empty match steps lastIndex one on and matching goes on from there:
`'aaa'|replace(r/a*/g, '-')` → `--` · `'abc'|replace(r//g, '-')` → `-a-b-c-` ·
`'ab'|replace(r/x*|a/g, '-')` → `-a-b-` (Perl's `s///g` gives `--b-`). `g`
starts at 0 whatever lastIndex was and ends at 0: with `re = r/a/g`,
`re.test('xa')` leaves lastIndex `2`, then `'aXa'|replace(re, '-')` → `-X-` and
lastIndex is `0`. `y` matches only at lastIndex and moves it: after
`r/a/y.test('a')`, `'aaa'` → `a-a`, lastIndex `2`; `'aab'` with `r/a/y` →
`-ab`, with `r/a/gy` → `--b`; `'baa'` with `r/a/gy` → `baa`. Neither flag:
the first match from 0, lastIndex untouched (`r/a/` after `test('xa')`:
lastIndex `0`, `'aXa'` → `-Xa`, lastIndex `0`). A replacer
gets `(matched, captures..., position, string[, groups])`; the groups object is
engine-built, so it iterates in group order: `'ab'|replace(r/(?<z>a)(?<b>b)/, f)`
with `f` looping over `g` → `z=a;b=b;`; a group that did not take part is
undefined, a duplicate name keeps its first place. Its null prototype
(`{{ g }}` → `TypeError: val.toString is not a function`) is open, k44. Seam:
Runtime `Regex->symbol_replace` / `_regexp_exec`.

## `\w` is ASCII — ADR 0005, mechanism in Lib

The engine's own `\w` (wordcount's `/\w+/g`) is `[A-Za-z0-9_]`:
`'héllo wörld_1 ünï'|wordcount` → `5` · `'a😀b'|wordcount` → `2` ·
`'ǅx Ⅳ'|wordcount` → `1`. Seam: Lib `js_word_class`. A template regex literal
is a different path: `'é'|replace(r/\w/, '-')` → `é` upstream, `-` in the port
(k49).

## `\d` is ASCII, `/i` without `u` folds only ASCII — ADR 0005, mechanism in Lib

urlize's emailRe is
`` /^[\w.!#$%&'*+\-\/=?\^`{|}~]+@[a-z\d\-]+(\.[a-z\d\-]+)+$/i ``.
`\d` is `[0-9]`: `'a@x3.com'|urlize` takes the `mailto:` branch, `'a@x٣.com'`
(U+0663) does not — tldRe links it as `http://a@x٣.com`. `/i` without `u`
canonicalises through toUpperCase but never maps a character above U+007F onto
ASCII, so `[a-z]` matches the 52 ASCII letters only: `'a@X.COM'` → `mailto:` ·
`'a@ſ.com'` (U+017F, upper `S`) · `'a@Kx.com'` (U+212A KELVIN SIGN, lower `k`) ·
`'a@ıx.com'` (U+0131, upper `I`) → no `mailto:`; the local part's `\w` is ASCII
as well: `'é@x.com'` → no `mailto:`. Perl's `/i` would take ſ and K (not ı),
its `\w` é and its `\d` ٣. Seams: Lib `js_digit_class` and `js_word_class`;
Filters spells `[a-z]` under `/i` as `[A-Za-z]` without `/i`.

## Stringification of containers — follows from k3/k6, mechanism in Runtime

`{{ [3,1,2] }}` → `3,1,2` · `{{ {} }}` → `[object Object]`.

## Regex literals — decided, ADR 0013

`{{ r/^h.l/.test(s) }}` → `true`. Oracle AST dumps a regex as
`{ "regex": <source>, "flags": <flags> }`.

## Callables, kwargs, `this`, callback API — decided, ADR 0009

## Escaping — port as is, no decision needed

Autoescape is **on by default**. The escape map is `& " ' < >` **plus backslash**:
`'` → `&#39;`, `\` → `&#92;`; backtick is not escaped. `urlencode` follows
`encodeURIComponent`: `'a b&c'` → `a%20b%26c`.

## urlencode: encodeURIComponent, destructuring, for-in — port as is, mechanism in Lib and Runtime

encodeURIComponent leaves `A-Z a-z 0-9 - _ . ! ~ * ' ( )` and writes every
other code point as the uppercase %XX of its UTF-8 bytes:
`"-_.!~*'()a b&c/?#[]"|urlencode|safe` → `-_.!~*'()a%20b%26c%2F%3F%23%5B%5D` ·
`'😀'|urlencode` → `%F0%9F%98%80`. It walks code units (ADR 0012); a lone
surrogate has no UTF-8 form and throws: `'😀'|first|urlencode` →
`URIError: URI malformed`. Seam: Lib `js_encode_uri_component`.

An array goes through `keyvals.map(([k, v]) => ...)`, and that pattern runs the
iteration protocol on each element: an array by element, a string — a
SafeString's value too — by code point, `undefined` past the end:
`[['a','b','c'], ['x'], '😀b']|urlencode` →
`a=b&amp;x=undefined&amp;%F0%9F%98%80=b` · `[m()]|urlencode` with `m` a macro
returning `a😀b` → `a=%F0%9F%98%80`. Any other element has no Symbol.iterator
and throws V8's TypeError, the value rendered as for a call (Runtime
`_js_not_callable_text`, above): `[5]|urlencode` → `TypeError: number 5 is not
iterable (cannot read property Symbol(Symbol.iterator))` · `[1.5]` →
`number 1.5 ...` · `[true]` → `boolean true ...` · `[none]` → `object null ...`
· `[u]` → `undefined ...` · `[{}]` → `object ...` · `[m]` with `m` a macro →
`function ...`. Seam: Runtime `js_array_destructure`.

Any other non-string goes through `lib._entries(obj)`, a for-in, which over
undefined, null, a number, a boolean or a function enumerates nothing: `5`,
`none`, `u`, `true`, `1/0` and a macro `m` all `|urlencode` to `''`;
`{a: 1, b: 'x y'}|urlencode` → `a=1&amp;b=x%20y`. A primitive string never gets
there (`lib.isString` comes first); its for-in indices elsewhere are k59. Seam:
Lib `keys`.

## Array.prototype.sort — decided, ADR 0017, mechanism in Lib

The Array `sort` member and the `sort` / `dictsort` filters all run one port
of V8 13.6.233.17's TimSort (`array-sort.tq`), so an inconsistent comparator
gets V8's calls and V8's result too. Without a comparefn two elements compare
as their ToStrings in UTF-16 code-unit order: `[10,9,1,100,25,2].sort()` →
`1,10,100,2,25,9` · `[1,'a',true,null,9,10,2,u].sort()|join(',')` →
`1,10,2,9,a,,true,` (null sorts as `'null'`). undefined goes last and is never
passed to the comparator: `[u,'z','a'].sort()` → `a,z,` · with `cmp` logging
its `(a, b)`, `[3,u,1,u,2].sort(cmp)|dump` → `[1,2,3,null,null]` after the
calls `1,3 2,1 2,3 2,1`. A comparefn is called `(x, y)` without `this`, its
result goes through ToNumber, NaN counts as +0 and only a negative result puts
x first: a macro printing `x` leaves `[5,3,9,1]` as it is, one printing
` {{ a - b }} ` (with spaces) sorts it to `1,3,5,9`, `-0` leaves it, and
`-Infinity` turns `[5,3,9,1,7,2,8]` into `8,2,7,1,9,3,5`. A comparefn that is
neither undefined nor callable throws before anything else, even on an empty
array: `[].sort(5)` → `TypeError: The comparison function must be either a
function or undefined: 5`. Seam: Lib `js_array_sort`, its call sequences
pinned by `t/data/js-array-sort.json` (`maint/js-array-sort-fixtures`).

The value in that TypeError is V8's NoSideEffectsToString. A primitive shows
as its ToString, a string uncut. `[1]` → `[object Array]`, `r/a/` →
`[object RegExp]`, `'a'|safe` → `[object Object]`. A plain object (a dict
literal, a caller hash, keyword arguments) shows as `#<Object>` (`{}`), except:

- an own `toString` key, whatever it holds, makes it `[object Object]`
  (`{'toString': 1}`, `{'toString': u}`, `sort(toString=1)`);
- so does an own `constructor` that is no named function (`{'constructor':
  1}`, `''`, `u`, `none`, `[]`, a SafeString, a context hash `{"constructor":
  "x"}`);
- an own `constructor` that is a named function shows by its name:
  `{'constructor': m}` with a macro `m` → `#<macro>`. In node, `function
  foo(){}` → `#<foo>` and an anonymous function → `[object Object]`.

Seam: Runtime `_js_no_side_effects_to_string` over
`_js_no_side_effects_to_maybe_string`; the name comes from `_js_function_name`.
Open: a Perl coderef has no name yet, so the port shows `[object Object]`
where upstream shows `#<macro>` (k88). A dict literal's `'__proto__'` key sets
the prototype upstream (`{'__proto__': {'toString': 1} }` → `[object Object]`,
`{'__proto__': {'a': 1} }.a` → `1`) but is an own key in the port (`#<Object>`,
empty). That one has no card yet; it is noted on k17.

## JSON.stringify (dump) — port as is, mechanism in Lib

`dump(spaces)` is `JSON.stringify(obj, null, spaces)`.

**The gap is V8's.** A number above 0 gives its integer part in spaces, at
most ten: `[1]|dump(2.9)` → `[\n  1\n]` · `dump(11)` → ten spaces. A number
in (0, 1) gives an empty gap that still breaks lines, which is not what the
spec says: `[1]|dump(0.5)` → `[\n1\n]` · `{'a': 1}|dump(0.5)` →
`{\n"a": 1\n}`. A string gives its first ten code units:
`dump('abcdefghijkl')` → `[\nabcdefghij1\n]`. `-1`, `true`, `''` and `0/0`
give no gap.

**Strings go through QuoteJSONString, well-formed.** `"`, `\` and the C0
controls are escaped (the short form, else `\u00XX`). A lone surrogate becomes
`\uXXXX`: `'😀'|first|dump` → `"\ud83d"`. U+007F, U+2028 and U+FEFF stay as
they are.
A pair that a caller spells as two surrogate characters is the one character,
as a value and as a key (ADR 0012).

**Values:**

- undefined and a function are left out of an object, are `null` in an array,
  and dump to '' at the top: `u|dump` and `m|dump` → '' · `[u, m]` → `[null,null]` ·
  `{'a': u, 'b': m, 'c': 1}` → `{"c":1}`.
- NaN and ±Infinity are `null`, and `-0` is `0`.
- A callable `toJSON` member is called with the key and its result is
  serialized: `{'toJSON': m}|dump` → `{"val":"T","length":1}`, the macro's
  SafeString. A `toJSON` that is not callable is a plain property:
  `{"toJSON":5,"a":1}`.
- A SafeString is an object with own `val` and `length`: `m()|dump` →
  `{"val":"ab","length":2}`. A regex is `{}`.
- Keys come in Lib `keys` order (ADR 0011).

**A circle throws V8's text.** `a.push(a)` then `a|dump` gives `TypeError:
Converting circular structure to JSON\n    --> starting at object with
constructor 'Array'\n    --- index 0 closes the circle`. A link through an
object prints as `|     property 'x' -> object with constructor 'Array'`, the
empty key as `<anonymous>`. Past three links V8 prints the first two, then
`|     ...`, then the last.

Seam: Lib `js_json_stringify`.

## hasOwnProperty, groupby, toArray — port as is, mechanism in Lib

`lib.hasOwnProp` is `Object.prototype.hasOwnProperty.call(obj, k)`. It runs
ToPropertyKey(k) first, then ToObject(obj), which throws on undefined and null:
`[u]|groupby('a')` and `[{'a': null}]|groupby('a.b')` → `TypeError: Cannot
convert undefined or null to object`. Only a key whose ToPrimitive throws
shows the order: `[u]|groupby({'toString': m})` → `TypeError: Cannot convert
object to primitive value`. The port runs no own `toString` member (k44), so it
throws the ToObject text there. Over `[{'k': 1}]` upstream throws the same
TypeError, while the port renders its groupby result without an error.

Measured through `groupby(attr)`, the own properties are:

- an array: its indices and `length`;
- a string: its code-unit indices and `length`;
- a SafeString: `val` and `length`;
- a regex: `lastIndex`;
- a number or a boolean: nothing;
- a function: `length` and `name` in JS, nothing in the port (k88).

groupby's result keys are the attribute values' ToPropertyKey:
`[{'a': 1}, {'a': '1'}, {'a': true}, {'a': 'true'}]|groupby('a')` iterates
`1=2;true=2;`. With throwOnUndefined the message is built from `${val}`, so
`groupby(1.5)` → `groupby: attribute "1.5" resolved to undefined` and
`groupby(['a','b'])` → `... "a,b" ...`.

`lib.toArray`, which select and reject run their input through, is
`Array.prototype.slice.call(obj)`:

- ToObject comes first: `u|select` → `TypeError: Cannot convert undefined or
  null to object`.
- The length goes through ToLength: with `'0': 'a', '1': 'b'`, a length of
  `2.5` or `'2'` gives `a,b` and `-1` gives nothing.
- A string is its String object: `'ab'|select|join(',')` → `a,b`. A number has
  no length: `[]`.
- A missing index never reaches the filter: `{'length': 3, '1': 'b'}|select|length` → `1`.
- A length of 2^32 or more (`4294967296`, `1/0`) throws `RangeError: Invalid
  array length`.

Seams: Lib `has_own_prop`, `get_attr_getter`, `group_by`, `to_array`.

## for-in over a SafeString — port as is, mechanism in Lib

dictsort walks its value with `for (k in val)`, and that loop also visits
inherited enumerable properties. A SafeString inherits `valueOf` and
`toString`, which are assigned onto SafeString.prototype, so `m()|dictsort`
iterates `length;toString;val;valueOf;`. `lib._entries` and `lib.keys` (used
by urlencode and dump) keep own keys only: `m()|urlencode` →
`val=x&amp;length=1`. Open: in JS the two inherited values are functions, in
the port they are undefined (k70), and `.val` reads empty (k72). Seams: Lib
`js_for_in_keys` for the for-in, `keys` for own keys.

## Object.prototype names in the filter and test registries — open, k87

`env.filters` and `env.tests` are plain JS objects, so a name of an
Object.prototype member finds that member:

- `[1, 2]|select('constructor')` and `select('toString')` select nothing;
- `{{ 1 is constructor }}` → `false`;
- `{{ 1|constructor }}` → `1`;
- `{{ 1|toString }}` → `[object Object]`.

`__proto__` is not callable: `[1]|select('__proto__')` → `TypeError:
test.call is not a function`, and `1|__proto__` → `TypeError:
env.getFilter(...).call is not a function`. For every one of these the port
throws `test not found: X` or `filter not found: X` (k87).

## Loaders: node's path, fs and console — decided, ADR 0018, mechanism in Lib

`Loader::resolve` and `FileSystemLoader` call node built-ins, and their Perl
look-alikes differ. Lib's `node_*` functions are ports of node v24.19.0's own
posix `lib/path.js` and of its `fs` behaviour. Fixtures from
`maint/node-builtins-fixtures` (`t/data/node-builtins.json`) pin them, and
`t/corpus/render-loaders.json` holds the cases measured with the oracle.

**Paths are lexical, POSIX.**

- `..` collapses on the string, and the file system is never asked.
  - `page.njk` in `views/sub` includes `../d.njk`, which is
    `<cwd>/views/d.njk`. That is both the cache key and the path an error
    names. `Path::Tiny->absolute` would leave `views/sub/../d.njk`.
  - A `..` inside a non-relative name collapses as well:
    `{% include "sub/../d.njk" %}` → `[d]`.
- `/` is the only separator.
- `resolve()`, `resolve('')` and `resolve('.')` are the cwd.
- Search paths go through `normalize`: `'./views//sub/../'` → `views/`.
- Each function refuses an argument that is no string, as node's
  `validateString` does, with a `TypeError`:
  - `[null]` as search paths → `The "path" argument must be of type string.
    Received null`.
  - `5` → `... Received type number (5)`, `true` → `type boolean (true)`,
    `[[...]]` → `an instance of Array`, `{...}` → `an instance of Object`.
  - `resolve` names the argument by its index (`The "paths[1]" argument`) and
    checks only those its loop reaches: `resolve(5, '/a')` is `/a`.
  - A falsy search-paths value (`null`, `''`, missing) is the default `['.']`,
    no error.
  - An object search path with an own `constructor` 1 makes V8 throw
    `Cannot use 'in' operator to search for 'name' in 1` instead.

  Seam: Lib `_node_validate_string` / `_node_determine_specific_type`; every
  kind is pinned in `t/data/node-builtins.json` (`pathArgs`).
- A relative name in `renderString` has no parent, so it is looked up as it
  stands: `{% include './d.njk' %}` → `d`.

**The search-path guard is a string-prefix test** (upstream bug, ported).
`p.indexOf(basePath) === 0 && existsSync(p)` lets a sibling directory through
when its name extends the search path's:

- With search path `views`, `../views2/secret.njk` renders `secret from
  views2`.
- `../outside.njk` → `Error: template not found: ../outside.njk`.
- A relative include that is refused is named by its resolved path:
  `(<root>/…/views/escape-parent.njk)\n  Error: template not found:
  <root>/…/outside.njk`.

**`readFileSync(p, 'utf-8')` uses the WHATWG decode.**

- A BOM stays: `EF BB BF` then `bom:{{ 1 + 1 }}` renders U+FEFF `bom:2`. It
  stays in an extended parent too.
- Every maximal subpart of an ill-formed sequence becomes one U+FFFD:
  - `E2 82` before `b` → 1 U+FFFD, then `b`;
  - `C0 80` → 2;
  - `ED A0 80` → 3;
  - `F4 90 80 80` → 4;
  - `F0 9F 98` → 1;
  - `FF` → 1.
- `F4 8F BF BF` decodes to U+10FFFF.
- Encode's strict decoder gives one U+FFFD per sequence and refuses U+10FFFF.
  Seam: Lib `_node_utf8_decode`.

**node's errors are libuv's.**

- A directory as a name gives `EISDIR: illegal operation on a directory, read`,
  with no path. The empty name is the search path itself, so it gives the same.
- A file that cannot be read gives `EACCES: permission denied, open '<path>'`.
- A dangling symlink is not there for `existsSync`. `readFileSync` gives
  `ENOENT: no such file or directory, open '<path>'`.
- The read takes no lock, so a file another process holds `LOCK_EX` on is read
  at once.
- Both are of kind `Error` (ADR 0010).

**`console.log` writes one line to STDOUT.** A boolean as the second argument,
`true` or `false`, prints `[nunjucks] Warning: you passed a boolean as the
second argument to FileSystemLoader, but it now takes an options object. See
http://mozilla.github.io/nunjucks/api.html#filesystemloader`. Seam: Lib
`node_console_log`.

**Out of scope:** `NodeResolveLoader`, `WebLoader`, and chokidar `watch`. A
truthy `watch` → `Error: watch requires chokidar to be installed`, which is
upstream's own branch when chokidar is not installed. The oracle hides
chokidar to measure it.

**Open:** a loader that is no `Loader` subclass. Upstream's `_initLoaders`
writes `loader.cache = {}` onto any object, and the port has no write seam for
it. The decision is pending on k94.

## Errors — port as is

Message format is asserted by upstream tests, keep it byte-identical:
`(unknown path) [Line 1, Column 15]\n  unknown block tag: foo` — note Line/Column
are **1-based in messages** while token/AST `lineno`/`colno` are **0-based**.
Error name: `Template render error`.
