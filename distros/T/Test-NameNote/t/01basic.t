use strict;
use warnings;

use Test::More tests => 11;

use_ok 'Test::NameNote';

my $n1 = Test::NameNote->new("foo");
is_deeply \@Test::NameNote::_notes, [\"foo"], "single note";

undef $n1;
is_deeply \@Test::NameNote::_notes, [], "single note gone";

$n1 = Test::NameNote->new("bar");
$n1 = Test::NameNote->new("baz");
is_deeply \@Test::NameNote::_notes, [\"baz"], "note overwrite";

{
    my $n2 = Test::NameNote->new("oo");
    is_deeply \@Test::NameNote::_notes, [\"baz", \"oo"], "lex scoped note in";
}
is_deeply \@Test::NameNote::_notes, [\"baz"], "lex scoped note out";
undef $n1;
is_deeply \@Test::NameNote::_notes, [], "baz out";

sub setnotes {
    my @h;
    push @h, Test::NameNote->new("a");
    push @h, Test::NameNote->new("b");
    push @h, Test::NameNote->new("c");
    return \@h;
}
{
    my $handle = setnotes();
    is_deeply \@Test::NameNote::_notes, [\"a", \"b", \"c"], "notes set in sub";
}
is_deeply \@Test::NameNote::_notes, [], "notes set in sub gone";

my $h = setnotes();
$h = [ reverse @$h ];
is_deeply \@Test::NameNote::_notes, [\"a", \"b", \"c"], "notes set in sub";
undef $h;
is_deeply \@Test::NameNote::_notes, [], "reverse order handle destroy";

