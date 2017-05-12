use t::TestYAMLTests tests => 8;

run {
    my $block = shift;
    my @values = eval $block->perl;
    is Dump(@values), $block->yaml, "Dump - " . $block->name
        unless $block->SKIP_DUMP;
    is_deeply [Load($block->yaml)], \@values, "Load - " . $block->name;
};

# typedef enum {
#         SVt_NULL,       /* 0 */
#         SVt_IV,         /* 1 */
#         SVt_NV,         /* 2 */
#         SVt_RV,         /* 3 */
#         SVt_PV,         /* 4 */
#         SVt_PVIV,       /* 5 */
#         SVt_PVNV,       /* 6 */
#         SVt_PVMG,       /* 7 */
#         SVt_PVBM,       /* 8 */
#         SVt_PVLV,       /* 9 */
#         SVt_PVAV,       /* 10 */
#         SVt_PVHV,       /* 11 */
#         SVt_PVCV,       /* 12 */
#         SVt_PVGV,       /* 13 */
#         SVt_PVFM,       /* 14 */
#         SVt_PVIO        /* 15 */
# } svtype;

# my $x = 222; "$x";
# my $y = 2.2; "$y";
# my $z = bless \$x, "zzz";
# my $c = sub { my $a = 1 };
# (\ undef, \ 42, \3.14, \\2, \"x", \$x, \$y, $z, $c, \*::);

__DATA__

=== Simple scalar ref
+++ perl
\ 42;
+++ yaml
--- !!perl/ref
=: 42

=== Ref to scalar ref
+++ perl
\\ "foo bar";
+++ yaml
--- !!perl/ref
=: !!perl/ref
  =: foo bar

=== Scalar refs an aliases
+++ perl
my $x = \\ 3.1415;
[$x, $$x];
+++ yaml
---
- !!perl/ref
  =: &1 !!perl/ref
    =: 3.1415
- *1

=== Ref to undef
+++ perl
my $x = {foo => \undef};

+++ yaml
---
foo: !!perl/ref
  =: ~

