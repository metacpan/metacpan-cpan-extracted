#!perl -w

use strict;
use Test::More;
use Carp ();

use Text::Xslate;
use Text::Xslate::Util qw(p);
use Text::Xslate::Bridge::TT2;

#note(Text::Xslate::Bridge::TT2->dump);

my $tx = Text::Xslate->new(
    syntax       => 'TTerse',
    module       => [ 'Text::Xslate::Bridge::TT2' ],
    warn_handler => \&Carp::croak,
);

my @set = (
    [ <<'T', <<'X' ],
    [% "Foo" | upper %]
    [% "Foo" | lower %]
    [% "foo" | ucfirst %]
    [% "FOO" | ucfirst %]
    [% "foo" | lcfirst %]
    [% "FOO" | lcfirst %]
    [% "  foo  bar  " | trim %]
    [% "  foo  bar  " | collapse %]
    [% "  foo  bar  " | null %]
    [% "<foo>" | html %]
    [% "foo" | repeat(3) %]
T
    FOO
    foo
    Foo
    FOO
    foo
    fOO
    foo  bar
    foo bar
    
    &lt;foo&gt;
    foofoofoo
X

    [ <<'T', <<'X' ],
[% FILTER indent("| ") -%]
foo
bar
baz
[% END -%]
T
| foo
| bar
| baz
X

    [ <<'T', <<'X' ],
[% FILTER indent("| ") -%]
foo
bar
baz
[% END -%]
T
| foo
| bar
| baz
X

    [ <<'T', <<'X' ],
[% FILTER format("[%s]") -%]
foo
bar
baz
[% END %]
T
[foo]
[bar]
[baz]
X

);

for my $d(@set) {
    my($in, $out, $msg) = @{$d};

    is eval { $tx->render_string($in) }, $out, $msg
        or diag $in;
    if($@){
        diag $@;
    }
}

eval {
    $tx->render_string(<<'T');
    [% FILTER eval() -%]
    foo
    [% END -%]
T
};
like $@, qr/not supported/;

done_testing;
