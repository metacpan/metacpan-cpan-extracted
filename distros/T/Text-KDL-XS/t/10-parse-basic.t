use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

my $doc = parse_kdl(<<'KDL');
greeting "hello" target="world"
package "kdl-rs" {
    version "0.4.0"
    author "Kat" email="kat@example.com"
}
KDL

isa_ok $doc, 'Text::KDL::XS::Document';

my $nodes = $doc->nodes;
is scalar(@$nodes), 2, 'two top-level nodes';

my $g = $nodes->[0];
is $g->name, 'greeting', 'first node name';
is scalar(@{ $g->args }),  1, 'one arg';
is $g->args->[0]->as_string, 'hello', 'arg value';
is scalar(@{ $g->props }), 1, 'one property';
is $g->prop('target')->as_string, 'world', 'property lookup';

my $pkg = $nodes->[1];
is $pkg->name, 'package', 'package node';
is scalar(@{ $pkg->children }), 2, 'package has 2 children';

my ($ver, $author) = @{ $pkg->children };
is $ver->name, 'version', 'child[0] name';
is $ver->args->[0]->as_string, '0.4.0', 'child[0] arg';

is $author->name, 'author', 'child[1] name';
is $author->prop('email')->as_string, 'kat@example.com', 'child[1] prop';

# as_data sanity
my $data = $doc->as_data;
is_deeply $data->[1], {
    name => 'package', type => undef,
    args => ['kdl-rs'], props => {},
    children => [
        { name => 'version', type => undef,
          args => ['0.4.0'], props => {}, children => [] },
        { name => 'author', type => undef,
          args => ['Kat'], props => { email => 'kat@example.com' },
          children => [] },
    ],
}, 'as_data round-trip';

done_testing;
