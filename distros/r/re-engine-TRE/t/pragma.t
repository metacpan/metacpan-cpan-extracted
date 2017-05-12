use strict;
use Test::More tests => 9;

=head1 DESCRIPTION

The pragma itself, its lexical effect.

Also syntax errors in regexen.

=cut

{
    use re::engine::TRE;
    ok("a" =~ /\</, "imported pragma");
    {
        no re::engine::TRE;
        sub f0 {
            ok(!("a" =~ /\</), "unimported pragma, lexical");
        }
        ok(!("a" =~ /\</), "unimported pragma");
    }
    ok(eval q{"a" =~ /\</} && !$@, "imported pragma goes into eval");
    ok(do { eval "use re::engine::TRE; qr/[/"; $@ }, "invalid regex");
    ok(do { eval "qr/[/"; $@ }, "invalid regex 2");
    sub f1 {
        ok("a" =~ /\</, "imported pragma, lexical");
    }
    f0();
    f2();
}
sub f2 {
    ok(!("a" =~ /\</), "default, lexical");
}
ok(!("a" =~ /\</), "default");
f1();

