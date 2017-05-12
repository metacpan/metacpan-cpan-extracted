#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Wraith qw ( $many $token );

# test case: a lambda-calculus-to-perl translator

my %expr_root = ( "kind" => "list", "defn" => [], "term" => [] );
my $rootref = \%expr_root;

my ($formlist, $form, $term, $varlist, $appterm, $aterm);
Wraith_rule->makerules(\$formlist, \$form, \$term, \$varlist, \$appterm, \$aterm);

$formlist = $many->(\$form); 
$form = ( (\$term >> $token->(';')) ** 
            sub { 
                [ { "kind" => "term", "body" => $_[0]->[0] } ]
            } 
        ) | 
        ( ($token->('[A-Za-z_]+') >> $token->('=') >> \$term >> $token->(';')) ** 
            sub {
                [ { "kind" => "defn", "name" => $_[0]->[0], "body" => $_[0]->[2] } ]
            } 
        );
$term = ( (\$appterm) ** sub { [ { "kind" => "appl", "body" => $_[0]->[0] } ] } ) |
        ( ($token->('\\\\') >> \$varlist >> $token->('\.') >> \$term) ** 
            sub {
                [ { "kind" => "abst", "para" => $_[0]->[1], "body" => $_[0]->[3] } ]
            } 
        );
$varlist = ($many->($token->('[A-Za-z_]+'))) ** sub { [ $_[0] ] }; 
$appterm = ($many->(\$aterm)) ** sub { [ $_[0] ] };
$aterm = ( ($token->('\(') >> \$term >> $token->('\)')) **
            sub { [ { "kind" => "applterm", "body" => $_[0]->[1] } ] } 
         ) |
         ( ($token->('[A-Za-z_]+')) ** sub { [ { "kind" => "applvar", "val" => $_[0]->[0] } ] } );

sub emitabst;
sub emitappl;
sub emitapplterm;
sub emitapplvar;
sub emitterm;
sub emitdefn;

my %emitmethods = (
    "term" => \&emitterm,
    "defn" => \&emitdefn,
    "appl" => \&emitappl,
    "abst" => \&emitabst,
    "applterm" => \&emitapplterm,
    "applvar" => \&emitapplvar
);

sub emitabst {
    my $abstref = $_[0];
    my $params = $abstref->{"para"};
    my $nparams = @$params;
    my $c_param = shift @$params;
    my $codefrag = undef;
    if ($nparams) {
        $codefrag .= "sub { my \$$c_param = \$_[0]; ";
    } 
    if (@$params) {
        $codefrag .= emitabst($abstref);
    } else {
        $codefrag .= $emitmethods{$abstref->{"body"}->{"kind"}}->($abstref->{"body"});
    }
    $codefrag.' }'
}

sub emitappl {
    my $applref = $_[0];
    my $oplist = $applref->{"body"};
    my $codefrag = undef;
    my $addparen = 0;
    while (@$oplist) {
        my $opitr = shift @$oplist;
        if ($addparen) {
            $codefrag .= '( ';
        }
        $codefrag .= $emitmethods{$opitr->{"kind"}}->($opitr);
        if ($addparen) {
            $codefrag .= ' )';
        }
        if (@$oplist) {
            $codefrag .= '->';
            $addparen = 1;
        }
    }
    $codefrag
}

sub emitapplterm {
    my $atermref = $_[0];
    $emitmethods{$atermref->{"body"}->{"kind"}}->($atermref->{"body"})
}

sub emitapplvar {
    my $varref = $_[0];
    '$'. $varref->{"val"}
}

sub emitterm {
    my $termref = $_[0];
    $emitmethods{$termref->{"body"}->{"kind"}}->($termref->{"body"})
}

sub emitdefn {
    my $defnref = $_[0];
    'my $' . $defnref->{"name"} .' = '. $emitmethods{$defnref->{"body"}->{"kind"}}->($defnref->{"body"}) .';'
}

my $res = $formlist->('true = \x y.x; x x y; Y = \f.(\x y.f (x x)) (\x y. f (x x));');

my @astlist;
for my $elt (@$res) {
    if (not $elt->[1]) {
        push @astlist, $elt->[0];
    }
}

ok(scalar @astlist eq 1);

for my $itr (@{$astlist[0]}) {
    if ($itr->{"kind"} eq "term") {
        push @{$expr_root{"term"}}, $itr;
    } else {
        push @{$expr_root{"defn"}}, $itr;
    }
}

my ($defnlist, $termlist) = ($rootref->{"defn"}, $rootref->{"term"});

my @defns = (
    'my $true = sub { my $x = $_[0]; sub { my $y = $_[0]; $x } };',
    'my $Y = sub { my $f = $_[0]; sub { my $x = $_[0]; sub { my $y = $_[0]; $f->( $x->( $x ) ) } }->( sub { my $x = $_[0]; sub { my $y = $_[0]; $f->( $x->( $x ) ) } } ) };'
);
my @terms = (
    '$x->( $x )->( $y )'
);

print "# defnlist: \n";
for my $defnitr (@$defnlist) {
    ok(emitdefn($defnitr) eq shift @defns);
}

print "# termlist: \n";
for my $termitr (@$termlist) {
    ok(emitterm($termitr) eq shift @terms);
}

done_testing();
