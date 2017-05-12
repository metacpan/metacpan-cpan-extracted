use Test::More tests => 7;
use lexicals;

sub foo {
    my %h = ( a => 1, b => 2);
    my @a = ( 'x', 'y', 3);
    my $s = 42;
    my $r = \$s;
    my $r2 = \\$s;
    my $l = lexicals;
    my $x = 7;
    my @x = (3, 4);
    my %x = (1, 3, 2, 1);

    $l = lexicals;
    is $l->{x}, 7, 'Scalar wins on match';
    is ref($l->{h}), 'HASH', 'lexical hashes are ok';
    is ref($l->{a}), 'ARRAY', 'lexical arrays are ok';
    is ref($l->{r}), 'SCALAR', 'lexical refs are ok';
    is ref($l->{r2}), 'REF', 'lexical refs are ok';
    is ref($l->{s}), '', 'lexical scalars are ok';
    is ${$l->{r2}}, $l->{r}, 'references are correct';
}

foo();
