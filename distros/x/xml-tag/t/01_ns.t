#! /usr/bin/perl
use Modern::Perl;
use XML::Tag;
use Test::More;

BEGIN {
    ns foo => qw< b c >, [a => 'aa'];
    ns ['' => 'bang'], [j=>'jj'],'k';
    ns [bar => ''], [a => 'aa'], 'b';
}

for 
( [ 'first tag of foo'                , '<foo:b/>'  , join '', foo::b {}  ]
# , [ 'second tag of foo'               , '<foo:c/>'  , join '', foo::c {}  ]
# , [ 'alias tag in foo'                , '<foo:aa/>' , join '', foo::a {}  ]
# , [ 'bang as defaut ns'               , '<k/>'      , join '', bang::k {} ]
# , [ 'bang as defaut ns with alias jj' , '<jj/>'     , join '', bang::j {} ]
, [ 'bar a' , '<bar:aa/>' , join '', a {} ]
, [ 'bar b' , '<bar:b/>'  , join '', b {} ]
) {
    my ( $desc, $expected, $got ) = @$_;
    is ( $got, $expected, $desc );
}

{ my $warn;
    local $SIG{__WARN__} = sub { $warn = shift };
    ns [], qw< ZER EZR ZEE >;
    ok
    ( (not $warn), "empty spec means 'no NS'" );
}


done_testing;

# TODO: how to test bar?

