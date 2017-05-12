#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 4;
use WWW::Webrobot::XML2Tree;
use WWW::Webrobot::Tree2Postfix;


my $unary_operator = {
    'uminus' => sub { -($_[0]) },
};

my $binary_operator = {
    'plus'  => sub { $_[0] + $_[1] },
    'minus' => sub { $_[0] - $_[1] },
};

my $predicate = {
    atom => sub {
        my ($self, $tree) = @_;
        return $tree->{value};
    },
};

my $parser = new WWW::Webrobot::XML2Tree();
my $evaluator = WWW::Webrobot::Tree2Postfix -> new(
    $unary_operator, $binary_operator, $predicate, "plus"
);

sub eval_xml {
    my ($name, $result, $xml) = @_;
    my $tree = $parser -> parse($xml);
    $evaluator -> tree2postfix($tree);
    my ($value, $error) = $evaluator -> eval_postfix("self");
    is($value, $result, $name) or diag($error);
}

eval_xml("atom", 3, <<EOF);
    <atom value='3'/>
EOF

eval_xml("uminus atom", -3, <<EOF);
    <uminus>
        <atom value='3'/>
    </uminus>
EOF

eval_xml("complex expression", 1, <<EOF);
    <uminus>
        <minus>
            <plus>
                <atom value='7'/>
                <atom value='11'/>
            </plus>
            <atom value='17'/>
            <atom value='5'/>
            <uminus><atom value='3'/></uminus>
        </minus>
    </uminus>
EOF

eval_xml("complex expression", -11, <<EOF);
    <minus>
        <plus>
            <atom value='7'/>
            <atom value='11'/>
        </plus>
        <atom value='17'/>
        <atom value='5'/>
        <uminus><atom value='3'/></uminus>
        <plus>
            <atom value='2'/>
            <atom value='3'/>
            <atom value='5'/>
        </plus>
    </minus>
EOF


1;
