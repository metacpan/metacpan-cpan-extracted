=pod

Test that lexical importing works, check BEGIN-ish stuff etc.

=cut

use strict;
use Test::More tests => 8;
use re::engine::Plugin ();

like "a", qr/^a$/, "import didn't run, perl's regex engine in effect";

BEGIN {
    re::engine::Plugin->import(
        exec => sub { $_[0]->pattern eq $_[1] }
    );
}

ok "^hello" =~ /^hello/ => "regex modified to match a literal pattern";

{
    BEGIN {
        re::engine::Plugin->import(
            exec => sub { $_[0]->pattern ne $_[1] }
        );
    }

    ok "^hello" !~ /^hello/ => "regex modified not to match a literal pattern";
    {
        BEGIN {
            re::engine::Plugin->import(
                exec => sub { $_[0]->pattern eq '^[abc]$' }
            );
        }
        ok "whatever" =~ /^[abc]$/ => "regex modified to match some exact nonsense";
        BEGIN { re::engine::Plugin->unimport };
        ok "whatever" !~ /^[abc]$/ => "regex modified to match some exact nonsense unimported";
    }
    ok "^hello" !~ /^hello/ => "regex modified not to match a literal pattern";
}

ok "^hello" =~ /^hello/ => "regex modified to match a literal pattern";

# Another import at the same scope
BEGIN {
    re::engine::Plugin->import(
        exec => sub { $_[0]->pattern ne $_[1] }
    );
}

ok "^hello" !~ /^hello/ => "regex modified not to match a literal pattern";
