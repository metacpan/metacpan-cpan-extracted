# Operator Coercion Ztests

The three `*-coercion.zzs` scripts in this directory are portable
language conformance tests for `docs/operator-coercion-rules.md`:

- `numeric-coercion.zzs`,
- `string-coercion.zzs`,
- `boolean-coercion.zzs`.

Keep these tests focused on operator-visible semantics. Do not add
runtime-specific implementation checks, implementation matrix update
checks, or `std/internals` API checks here. `std/internals` coercion
coverage belongs in `t/ztests/std/internals`.

When working on a runtime, run that runtime directly against these three
files before running broader suites.

```sh
perl -Ilib bin/zuzu t/ztests/lang/operators/numeric-coercion.zzs
perl -Ilib bin/zuzu t/ztests/lang/operators/string-coercion.zzs
perl -Ilib bin/zuzu t/ztests/lang/operators/boolean-coercion.zzs
./extras/zuzu-rust/target/debug/zuzu-rust t/ztests/lang/operators/numeric-coercion.zzs
./extras/zuzu-rust/target/debug/zuzu-rust t/ztests/lang/operators/string-coercion.zzs
./extras/zuzu-rust/target/debug/zuzu-rust t/ztests/lang/operators/boolean-coercion.zzs
node extras/zuzu-js/bin/zuzu-js t/ztests/lang/operators/numeric-coercion.zzs
node extras/zuzu-js/bin/zuzu-js t/ztests/lang/operators/string-coercion.zzs
node extras/zuzu-js/bin/zuzu-js t/ztests/lang/operators/boolean-coercion.zzs
```
