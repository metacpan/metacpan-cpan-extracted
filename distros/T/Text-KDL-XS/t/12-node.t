use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

sub Value { Text::KDL::XS::Value->new(@_) }
sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}

# prop() reads the props array itself, so it works on hand-built nodes and
# sees every change made to props.
{
    my $node = Text::KDL::XS::Node->new(name => 'n', props => [ [ k => Value(type => 'string', value => 'v') ] ]);
    is $node->prop('k')->as_string, 'v', 'prop finds a property of a hand-built node';
    is $node->prop('missing'), undef, 'prop returns undef for a missing key';
}
{
    my $node = parse_kdl("n a=1 b=2 a=3\n")->nodes->[0];
    is $node->prop('a')->as_perl, 3, 'the rightmost repeated key wins';

    push @{ $node->props }, [ a => Value(type => 'number', value => 99) ];
    is $node->prop('a')->as_perl, 99, 'prop sees a pushed property';

    shift @{ $node->props };
    is $node->prop('b')->as_perl, 2, 'prop is not shifted off by one after removing a property';

    $node->{props} = [ [ z => Value(type => 'null') ] ];
    ok $node->prop('z')->is_null, 'prop sees a replaced props array';
    is $node->prop('a'), undef, 'keys of the replaced array are gone';
}
dies_like { Text::KDL::XS::Node->new(name => 'n')->prop(undef) } qr/key is required/, 'prop(undef) dies';

# Constructor validation.
dies_like { Text::KDL::XS::Node->new } qr/'name' is required/, 'new without a name dies';
dies_like { Text::KDL::XS::Node->new(name => undef) } qr/'name' is required/, 'new with an undef name dies';
for my $list (qw(args props children)) {
    dies_like { Text::KDL::XS::Node->new(name => 'n', $list => {}) } qr/'$list' must be an ARRAY reference/,
        "new with a non-ARRAY $list dies";
}
dies_like { Text::KDL::XS::Node->new(name => 'n', prop_index => {}) } qr/unknown field 'prop_index'/,
    'new with an unknown field dies';
dies_like { Text::KDL::XS::Node->new('n') } qr/odd number of arguments/, 'new with an odd argument list dies';
dies_like { Text::KDL::XS::Document->new(nodes => {}) } qr/'nodes' must be an ARRAY reference/,
    'Document->new with non-ARRAY nodes dies';

# as_data converts Value objects and passes plain scalars through.
{
    my $node = Text::KDL::XS::Node->new(
        name     => 'n',
        args     => [ 1, Value(type => 'bool', value => 1), undef ],
        props    => [ [ k => 'v' ] ],
        children => [ Text::KDL::XS::Node->new(name => 'c', args => ['x']) ],
    );
    is_deeply $node->as_data, {
        name     => 'n',
        type     => undef,
        args     => [ 1, 1, undef ],
        props    => { k => 'v' },
        children => [ { name => 'c', type => undef, args => ['x'], props => {}, children => [] } ],
    }, 'as_data handles plain scalars in hand-built nodes';
}

done_testing;
