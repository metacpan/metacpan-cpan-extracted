use strict;
use Test::More tests => 3;
use re::engine::TRE;

=head1 DESCRIPTION

Test C<\0> in strings and patterns

=cut

ok "foo\1bar" !~ /^foo$/ => '\\1 in str';
SKIP: {
    skip "regnexec() doesn't actually allow NULL in the subject?", 1;
    ok "foo\0bar" !~ /^foo$/ => '\\0 in str';
}

my $str = "foo\0bar";
ok "foo\0bar" =~ /^$str$/ => '\\0 does not cut off regex';




