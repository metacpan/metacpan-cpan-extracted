# Struct for Perl

> Perl port of the canonical TypeScript implementation.
> Status: complete — full canonical parity, 700+ corpus cases passing.

For motivation, language-neutral concepts, and the cross-language
parity matrix, see the [top-level README](../README.md).


## Install

Inside the monorepo:

```bash
cd perl
make test
```

Tested with Perl 5.38. Module: [`lib/Voxgig/Struct.pm`](./lib/Voxgig/Struct.pm).

Zero runtime third-party dependencies — only core `Scalar::Util`,
`List::Util` and `B`. The insertion-ordered hash type lives in-tree
as the `Voxgig::Struct::OrderedHash` tie class at the top of the
module.


## Quick start

```perl
use Voxgig::Struct;

my $store = Voxgig::Struct::parse_json('{"db":{"host":"localhost"}}');
my $val   = Voxgig::Struct::getpath($store, 'db.host');
# $val eq "localhost"
```

`getpath($store, $path)` reads a deep value by dot path (store first, then
path — matching the canonical TS argument order):

<!-- example: getpath/basic#deep -->
```perl
Voxgig::Struct::getpath(
  Voxgig::Struct::jm(a => Voxgig::Struct::jm(b => Voxgig::Struct::jm(c => 42))),
  'a.b.c',
);   # 42
```
<!-- => 42 -->


## Function reference

Source: [`lib/Voxgig/Struct.pm`](./lib/Voxgig/Struct.pm).

Functions live in the `Voxgig::Struct::` namespace. The port keeps the
canonical TS names (`isnode`, `getpath`, `keysof`, …) rather than
`snake_case`ing them — this means the function-name table is the same
across every Voxgig port.

### Core types

The Perl port uses plain Perl scalars / array refs / hash refs to model
JSON values, with two refinements:

| JSON type | Perl form                                  |
|-----------|--------------------------------------------|
| object    | `HASH` ref, tied to `Voxgig::Struct::OrderedHash` so map key insertion order is preserved (matches the canonical TS contract). |
| array     | `ARRAY` ref.                               |
| string    | plain scalar with `SVf_POK` only.          |
| number    | plain scalar with `SVf_IOK` or `SVf_NOK` set. The in-tree JSON parser sets this so `getpath` can distinguish `"0.0"` (string path) from `0.0` (numeric path), matching TS's `typeof path` branch. |
| true / false | `$Voxgig::Struct::JTRUE` / `$Voxgig::Struct::JFALSE` — blessed scalar singletons that overload booleans, `0+`, and `""` so they behave correctly in arithmetic, comparison, and stringification. |
| null      | `$Voxgig::Struct::JNULL` — distinct from Perl `undef` (which represents "absent"). |

### Sentinels

`SKIP` and `DELETE` are insertion-ordered hashes blessed
`Voxgig::Struct::Sentinel`; `setprop` recognises them and either
preserves or removes the slot.

### JSON parser

`Voxgig::Struct::parse_json($text)` returns a structure that uses the
type rules above (in particular, `Voxgig::Struct::OrderedHash`-tied maps and
flag-marked numbers). `Cpanel::JSON::XS` / `JSON::PP` are not used
because they don't preserve insertion order.

### What's wired

- All 29 **minor utilities**: `isnode`, `ismap`, `islist`, `iskey`,
  `isempty`, `isfunc`, `size`, `slice`, `pad`, `typify`, `getelem`,
  `getprop`, `strkey`, `keysof`, `haskey`, `items`, `flatten`,
  `filter`, `escre`, `escurl`, `join`, `jsonify`, `stringify`,
  `pathify`, `clone`, `delprop`, `setprop`, `typename`, `getdef`.
- Major utilities: `walk`, `merge`, `setpath`, `getpath`.
- `inject` (three-phase key processing) with `_injectstr` (full
  and partial backtick refs) and `_injecthandler` (default command
  dispatcher).
- `transform` and the 11 transform commands: `$DELETE`, `$COPY`,
  `$KEY`, `$META`, `$ANNO`, `$MERGE`, `$EACH`, `$PACK`, `$REF`,
  `$FORMAT`, `$APPLY` (plus the `FORMATTER` table for $FORMAT:
  `identity`, `upper`, `lower`, `string`, `number`, `integer`,
  `concat`).
- `validate` and the 15 validate checkers: `$STRING`, `$NUMBER`,
  `$INTEGER`, `$DECIMAL`, `$BOOLEAN`, `$NULL`, `$NIL`, `$MAP`,
  `$LIST`, `$FUNCTION`, `$INSTANCE`, `$ANY`, `$CHILD`, `$ONE`,
  `$EXACT`.
- `select` and the 4 select operators: `$AND`, `$OR`, `$NOT`,
  `$CMP` (with `$GT`, `$LT`, `$GTE`, `$LTE`, `$LIKE`).
- Type constants (`T_any`, `T_noval`, `T_boolean`, …, `T_node`),
  mode constants (`M_KEYPRE` / `M_KEYPOST` / `M_VAL`), modename
  table, sentinels (`SKIP`, `DELETE`), boolean singletons
  (`JTRUE`, `JFALSE`), null singleton (`JNULL`), absence sentinel
  (`NONE`).
- Injection helpers: `Injection` state (built as a hashref with
  `_inj_child` / `_inj_descend` / `_inj_setval`), `checkPlacement`,
  `injectorArgs`, `injectChild`.
- Builder helpers: `jm` (insertion-ordered map literal), `jt`
  (list literal).

## Examples

Each example below uses `jm` (insertion-ordered map literal) and `jt`
(list literal) to build inputs; the inline comment shows the value the
call returns.

### Predicates

<!-- example: minor/isnode#map -->
```perl
Voxgig::Struct::isnode(Voxgig::Struct::jm(a => 1));   # true (a map is a node)
```
<!-- => true -->

<!-- example: minor/ismap#map -->
```perl
Voxgig::Struct::ismap(Voxgig::Struct::jm(a => 1));   # true
```

<!-- => true -->

<!-- example: minor/islist#list -->
```perl
Voxgig::Struct::islist([1, 2]);   # true
```

<!-- => true -->

<!-- example: minor/iskey#str -->
```perl
Voxgig::Struct::iskey('name');   # true
```

<!-- => true -->

<!-- example: minor/isempty#empty -->
```perl
Voxgig::Struct::isempty([]);   # true
```

<!-- => true -->

### Type inspection

`typify` returns a bit-field combining a kind flag (`T_scalar` or `T_node`)
with a specific type flag; `typename` looks up a human-friendly name:

<!-- example: minor/typify#int -->
```perl
Voxgig::Struct::typify(1);   # T_scalar | T_number | T_integer (201326720)
```

<!-- => 201326720 -->

<!-- example: minor/typename#map -->
```perl
Voxgig::Struct::typename(8192);   # 'map' (8192 == T_map)
```

<!-- => "map" -->

### Size, slice, pad

<!-- example: minor/size#three -->
```perl
Voxgig::Struct::size([1, 2, 3]);   # 3
```
<!-- => 3 -->

`slice` keeps the first *N*; a negative `start` drops the last *|start|*
items, and `end` is exclusive:

<!-- example: minor/slice#mid -->
```perl
Voxgig::Struct::slice([1, 2, 3, 4, 5], 1, 4);   # [2, 3, 4]
```
<!-- => [2, 3, 4] -->

<!-- example: minor/slice#strhead -->
```perl
Voxgig::Struct::slice('abcdef', -3);   # 'abc'  (keeps the first 3)
```
<!-- => "abc" -->

<!-- example: minor/pad#right -->
```perl
Voxgig::Struct::pad('a', 3);   # 'a  '  (pad right to width 3)
```
<!-- => "a  " -->

### Property access

<!-- example: minor/getprop#hit -->
```perl
Voxgig::Struct::getprop(Voxgig::Struct::jm(x => 1), 'x');   # 1
```
<!-- => 1 -->

`keysof` returns map keys sorted alphabetically:

<!-- example: minor/keysof#sorted -->
```perl
Voxgig::Struct::keysof(Voxgig::Struct::jm(b => 4, a => 5));   # ['a', 'b']
```
<!-- => ["a", "b"] -->

`getelem` is list-specific and supports negative-from-the-end indexing:

<!-- example: minor/getelem#neg -->
```perl
Voxgig::Struct::getelem([10, 20, 30], -1);   # 30
```

<!-- => 30 -->

`setprop` returns the parent with the key set; `delprop` returns it with the
key removed:

<!-- example: minor/setprop#set -->
```perl
Voxgig::Struct::setprop(Voxgig::Struct::jm(a => 1), 'b', 2);   # { a => 1, b => 2 }
```

<!-- => {"a": 1, "b": 2} -->

<!-- example: minor/delprop#del -->
```perl
Voxgig::Struct::delprop(Voxgig::Struct::jm(a => 1, b => 2), 'a');   # { b => 2 }
```

<!-- => {"b": 2} -->

`haskey` reports whether a key is present (and not null/absent):

<!-- example: minor/haskey#hit -->
```perl
Voxgig::Struct::haskey(Voxgig::Struct::jm(a => 1), 'a');   # true
```

<!-- => true -->

`items` returns `[key, value]` pairs in canonical order:

<!-- example: minor/items#map -->
```perl
Voxgig::Struct::items(Voxgig::Struct::jm(a => 1, b => 2));   # [['a', 1], ['b', 2]]
```

<!-- => [["a", 1], ["b", 2]] -->

`strkey` coerces a key to its canonical string form (numbers truncate toward
zero; invalid keys become `''`):

<!-- example: minor/strkey#num -->
```perl
Voxgig::Struct::strkey(2.2);   # '2'
```

<!-- => "2" -->

### Filter

`filter` passes each `[key, value]` pair to the check and returns the
matching **values** (not the pairs):

<!-- example: minor/filter#gt3 -->
```perl
Voxgig::Struct::filter([1, 2, 3, 4, 5], sub {
  my ($pair) = @_;
  return $pair->[1] > 3;
});   # [4, 5]
```
<!-- => [4, 5] -->

### Path operations

`setpath` sets a deep value by dot path (store first, then path, then value)
and returns the store:

<!-- example: minor/setpath#nested -->
```perl
Voxgig::Struct::setpath(Voxgig::Struct::jm(a => 1, b => 2), 'b', 22);   # { a => 1, b => 22 }
```

<!-- => {"a": 1, "b": 22} -->

`pathify` renders a path arrayref as a dotted string:

<!-- example: minor/pathify#parts -->
```perl
Voxgig::Struct::pathify(['a', 'b', 'c']);   # 'a.b.c'
```

<!-- => "a.b.c" -->

### Tree operations

`merge` combines a list of nodes — last input wins, maps deep-merge, lists
merge by index:

<!-- example: merge#basic -->
```perl
Voxgig::Struct::merge([
  Voxgig::Struct::jm(a => 1, b => 2, k => [10, 20],
                     x => Voxgig::Struct::jm(y => 5, z => 6)),
  Voxgig::Struct::jm(b => 3, d => 4, e => 8, k => [11],
                     x => Voxgig::Struct::jm(y => 7)),
]);
# { a => 1, b => 3, d => 4, e => 8, k => [11, 20], x => { y => 7, z => 6 } }
```

<!-- => {"a": 1, "b": 3, "d": 4, "e": 8, "k": [11, 20], "x": {"y": 7, "z": 6}} -->

`clone` makes a deep copy:

<!-- example: minor/clone#deep -->
```perl
Voxgig::Struct::clone(Voxgig::Struct::jm(a => Voxgig::Struct::jm(b => [1, 2])));
# { a => { b => [1, 2] } }  (a deep copy)
```

<!-- => {"a": {"b": [1, 2]}} -->

`flatten` collapses one level of nested lists by default:

<!-- example: minor/flatten#nested -->
```perl
Voxgig::Struct::flatten([1, [2, [3]]]);   # [1, 2, [3]]  (one level by default)
```

<!-- => [1, 2, [3]] -->

### String / URL

`escre` escapes regex metacharacters; `escurl` percent-encodes URL-unsafe
characters; `join` joins list parts with a separator:

<!-- example: minor/escre#dots -->
```perl
Voxgig::Struct::escre('a.b+c');   # 'a\.b\+c'
```

<!-- => "a\\.b\\+c" -->

<!-- example: minor/escurl#space -->
```perl
Voxgig::Struct::escurl('hello world?');   # 'hello%20world%3F'
```

<!-- => "hello%20world%3F" -->

<!-- example: minor/join#sep -->
```perl
Voxgig::Struct::join(['a', 'b', 'c'], '/');   # 'a/b/c'
```

<!-- => "a/b/c" -->

### JSON serialisation

`jsonify($value)` pretty-prints with a 2-space indent by default; pass
`jm(indent => 0)` for the compact form:

<!-- example: minor/jsonify#map -->
```perl
Voxgig::Struct::jsonify(Voxgig::Struct::jm(a => 1));
# {
#   "a": 1
# }
```
<!-- => "{\n  \"a\": 1\n}" -->

<!-- example: minor/jsonify#compact -->
```perl
Voxgig::Struct::jsonify(Voxgig::Struct::jm(a => 1, b => 2), Voxgig::Struct::jm(indent => 0));
# '{"a":1,"b":2}'
```
<!-- => "{\"a\":1,\"b\":2}" -->

`stringify` is the compact, quote-light human form — keys are sorted and
object braces are kept; the second argument caps the length (the `...`
counts):

<!-- example: minor/stringify#max -->
```perl
Voxgig::Struct::stringify('verylongstring', 5);   # 've...'
```
<!-- => "ve..." -->

### Transform commands

A command like `$EACH` appears in **value** position — as the first element
of a list — mapping the sub-spec over every entry at `path`:

<!-- example: transform/each#basic -->
```perl
Voxgig::Struct::transform(
  Voxgig::Struct::jm(v => 1, a => Voxgig::Struct::jt(
    Voxgig::Struct::jm(q => 13), Voxgig::Struct::jm(q => 23))),
  Voxgig::Struct::jm(x => Voxgig::Struct::jm(y => Voxgig::Struct::jt(
    '`$EACH`', 'a',
    Voxgig::Struct::jm(q => '`$COPY`', r => '`.q`', p => '`...v`')))),
);
# { x => { y => [ { q => 13, r => 13, p => 1 }, { q => 23, r => 23, p => 1 } ] } }
```
<!-- => {"x": {"y": [{"q": 13, "r": 13, "p": 1}, {"q": 23, "r": 23, "p": 1}]}} -->

Putting a command in **key** position (or, for `$APPLY`, directly under a
map) is an error — commands must be list values:

<!-- example: transform/apply#badkey -->
```perl
Voxgig::Struct::transform(
  Voxgig::Struct::jm(),
  Voxgig::Struct::jm(x => '`$APPLY`'),
);
# dies: $APPLY: invalid placement in parent map.
```
<!-- throws: invalid placement in parent map -->

### Injection / validate / select

`inject` replaces backtick references in strings with values from the store:

<!-- example: inject#basic -->
```perl
Voxgig::Struct::inject(
  Voxgig::Struct::jm(x => '`a`', y => 2),
  Voxgig::Struct::jm(a => 1),
);   # { x => 1, y => 2 }
```

<!-- => {"x": 1, "y": 2} -->

`validate` checks data against a shape spec (the leaves are type checkers)
and dies on mismatch:

<!-- example: validate#shape -->
```perl
Voxgig::Struct::validate(
  Voxgig::Struct::jm(name => 'Ada', age => 36),
  Voxgig::Struct::jm(name => '`$STRING`', age => '`$INTEGER`'),
);   # { name => 'Ada', age => 36 }  (dies on mismatch)
```

<!-- => {"name": "Ada", "age": 36} -->

`select` finds children matching a query, tagging each with its `$KEY`:

<!-- example: select#query -->
```perl
Voxgig::Struct::select(
  Voxgig::Struct::jm(
    a => Voxgig::Struct::jm(name => 'Alice', age => 30),
    b => Voxgig::Struct::jm(name => 'Bob',   age => 25),
  ),
  Voxgig::Struct::jm(age => 30),
);   # [ { name => 'Alice', age => 30, '$KEY' => 'a' } ]
```

<!-- => [{"name": "Alice", "age": 30, "$KEY": "a"}] -->


## Regex

Uniform six-function regex API (see `/design/REGEX_API.md`). The Perl port
wraps Perl's built-in regex engine.

### API

| Function | Maps to |
|---|---|
| `re_compile(pattern, flags?)`         | `qr/$pattern/` |
| `re_test(pattern, input)`             | `$input =~ $re` |
| `re_find(pattern, input)`             | first match as `[whole, $1, ...]` or `undef` |
| `re_find_all(pattern, input)`         | all matches, one arrayref per match |
| `re_replace(pattern, input, repl)`    | `s/$re/$repl/g` (callable or template) |
| `re_escape(s)`                        | `quotemeta` equivalent |

### Dialect

Patterns must stay inside the **RE2 subset** documented in `/design/REGEX.md`.
Perl's regex supports backreferences, lookaround, recursion — none of
which are portable to the Go / Rust / C / Lua / Zig ports.

### Sharp edges

- **Catastrophic backtracking.** Perl's regex engine is backtracking
  but ships with optimisations (trie engine for alternation, etc.).
  The discovery panel runs P1/P2 in microseconds here, but other
  pathological shapes can still blow up. Stay flat.
- **Zero-width `replace`.** `re_replace("a*", "abc", "X")` returns
  `"XXbXcX"` — the ECMA convention shared by all PCRE/ECMA/.NET/Java/Onigmo engines plus the in-tree Thompson ports. Go (RE2) returns `"XbXcX"` instead; see `/design/REGEX_PATHOLOGICAL.md`.
- **UTF-8 handling.** Pass character strings (use `use utf8;` for
  literals, or `decode_utf8` for bytes). Encoding round-trip bugs in
  caller code can manifest as `cafÃ©` style mojibake at print time —
  the regex itself preserves character semantics.

See `/design/REGEX_PATHOLOGICAL.md` for the cross-port pathological-input panel.


## Tests

```bash
make test
```

The runner loads `../build/test/test.json` (the cross-port corpus)
and exercises each set the wired functions are responsible for.
