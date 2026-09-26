use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub string { Text::KDL::XS::Value->new(type => 'string', value => $_[0], type_annotation => $_[1]) }

# A node that uses $text as node name, node type annotation, argument,
# argument type annotation and property key.
sub node_of {
    my ($text) = @_;
    return Text::KDL::XS::Node->new(
        name            => $text,
        type_annotation => $text,
        args            => [ string($text, $text) ],
        props           => [ [ $text => string('v') ] ],
    );
}

sub reads_back {
    my ($kdl, $version, $text) = @_;
    my $node = eval { parse_kdl($kdl, version => $version)->nodes->[0] } or return 0;
    my $arg  = $node->args->[0];
    return $node->name eq $text && $node->type_annotation eq $text
        && $arg->is_string && $arg->value eq $text && $arg->type_annotation eq $text
        && $node->props->[0][0] eq $text;
}

# Strings that are keywords or look like numbers must not be written bare.
my @ambiguous = ('true', 'false', 'null', 'inf', '-inf', 'nan', '-1', '+1', '.5', '-.5', '+.5');
for my $version (qw(1 2 detect)) {
    my $parse_version = $version eq 'detect' ? 2 : $version;
    for my $text (@ambiguous) {
        my $kdl = emit_kdl(node_of($text), version => $version);
        ok reads_back($kdl, $parse_version, $text), "'$text' round-trips in every position (version $version)"
            or diag $kdl;
    }
    my $data = emit_kdl({ true => '-1', key => 'nan' }, version => $version);
    is_deeply [ map { [ $_->name, $_->args->[0]->value ] } @{ parse_kdl($data, version => $parse_version)->nodes } ],
        [ [ key => 'nan' ], [ true => '-1' ] ], "data mode keys and values round-trip (version $version)";
}

# Quoting is switched on only when it is needed.
is emit_kdl(node_of('plain')), qq{(plain)plain (plain)plain plain=v\n}, 'unambiguous text stays bare';
is emit_kdl({ n => 'true' }), qq{"n" "true"\n}, 'an ambiguous value quotes the whole document';
is emit_kdl({ n => 'true' }, version => 1), qq{n "true"\n}, 'v1 quotes string values anyway';
is emit_kdl({ true => 1 }, version => 1), qq{"true" 1\n}, 'v1 node names are checked';

# An explicit identifier_mode is respected.
is emit_kdl({ n => 'true' }, identifier_mode => 0), qq{n true\n}, 'identifier_mode 0 is kept when given';
is emit_kdl({ n => 'x' }, identifier_mode => 1), qq{"n" "x"\n}, 'identifier_mode 1 quotes everything';
is emit_kdl({ "caf\x{e9}" => 'x' }, identifier_mode => 2), qq{"caf\x{e9}" x\n}, 'identifier_mode 2 quotes non-ASCII';

done_testing;
