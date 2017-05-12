#!/usr/local/lib/perl -w

use strict;

#use Devel::TraceSAX;

use Carp;
use Test;
use XML::Filter::Dispatcher qw( :all );
use UNIVERSAL;

my $have_test_diff = eval "use Test::Differences; 1";

my $a = QB->new( "a", "<a/>" );
my @nodes_in_a = ( "", "a" );

my $abcd    = QB->new( "abcd", "<!--R--><?RR rr?><a>s<!--S--><?SS ss?><b>t<!--T--><?TT tt?><c>u<d id='1' name='n1'>v</d><d id='2'>w</d>x</c>y</b>z</a><!--Z1--><?Z1Z1 z1z1?>" );

my $nodes_in_abcd = 25;  ## Including the doc node :)
my @nodes_in_abcd =
              ( "", qw( R RRrr a s S SSss b t T TTtt c u d name id v d id w   x   y   z   Z1 Z1Z1z1z1 ) );
my @non_attr_nodes_in_abcd =
              ( "", qw( R RRrr a s S SSss b t T TTtt c u d         v d    w   x   y   z   Z1 Z1Z1z1z1 ) );
my @non_doc_non_attr_nodes_in_abcd =
              (     qw( R RRrr a s S SSss b t T TTtt c u d         v d    w   x   y   z   Z1 Z1Z1z1z1 ) );
my @end_nodes_in_abcd =
              (     qw( R RRrr   s S SSss   t T TTtt   u           v d    w d x c y b z a Z1 Z1Z1z1z1 ), "" );
my @elt_end_nodes_in_abcd = 
              (     qw(                                        d      d   c   b   a         ) );

my $abcdBcd = QB->new( "abcdBcd", "<a><b><c><d>1</d><d>2</d></c></b><B><c><d>3</d><d>4</d></c></B></a>" );

my $abc123  = QB->new( "abc123", "<a>1<b>2<c id='10'>3</c><c id='20'>3</c>2</b>1</a>" );

my $ab      = QB->new( "ab", "<a name='joe'><b id='1' name='harry'>b</b>A</a>" );

my $var     = QB->new( "var", "<a><b/></a>" );
my @nodes_in_var = ( "", qw( a b ) );

my $aaaabaa   = QB->new( "aaaabaa", "<a id='1'><a id='2'><a id='3'><b/><a/><a><a/></a></a></a></a>" );
my $aaaaaab   = QB->new( "aaaaaab", "<a id='1'><a id='2'><a id='3'><a/><a><a/></a><b/></a></a></a>" );
my $aaacb     = QB->new( "aaacb",   "<a id='1'><a id='2'><a id='3'/><c/></a><b/></a>" );
my $aaaacb    = QB->new( "aaaacb",  "<a id='1'><a id='2'><a id='3'><a id='4'/></a><c/></a><b/></a>" );

my $ns        = QB->new( "ns", "<a xmlns='default-ns' xmlns:foo='foo-ns'><foo:b/></a>" );

sub result_list {
    my $prefix = "";
    $prefix = shift() . "_" unless ref $_[0];
    my $suffix = "";
    $suffix = "_" . pop unless ref $_[-1];

    return [ map "$prefix$_$suffix", @{$_[0]} ]
}

my @log;

my $fold_constants;

sub rules {
    my @out;
    while ( @_ ) {
        push @out, shift;
        if ( ! @_ || ! ref $_[0] ) {
            push @out, sub {
                my ( $self ) = shift;
                my ( $foo ) = @_;
                my $xr = xvalue;
                push @log, join( "",
                    ( $foo->{Name}
                        || ( $foo->{Target} || "" ) . ( $foo->{Data} || "" )
                    ),
                    defined $xr && ( ref $xr eq "" || ref $xr eq "SCALAR" )
                        ? ( "_", ref $xr ? $$xr : $xr )
                        : (),
                );
            };
            next;
        }

        push @out, [ rules( @{shift()} ) ];
    }
    return @out;
}


sub d {
    my $qb = shift;
    my $rule = shift;

    my $options = @_ && ref( $_[-1] ) eq "HASH" ? pop : {};

    $options->{FoldConstants} = $fold_constants;

    my $expect = result_list @_;

    unless ( $have_test_diff ) {
        @_ = ( "Need Test::Differences to test", 1 );
        goto &skip;
    }

    my @rules = rules ref $rule ? @$rule : $rule;

#use Data::Dumper ; warn Dumper( \@rules );

    my $d = eval { XML::Filter::Dispatcher->new(
        Rules => \@rules,
        Vars => {
            foo => [ boolean => "bar" ],
        },
        %$options,
    ) };

    @log = ();
    if ( $d ) {
        $qb->playback( $d );
    }
    else {
        push @log, split /\n/, $@;
    }
    @_ = ( \@log, $expect, $rule );
    goto &eq_or_diff;

}


## NOTE: if you try this at home, it is *not* unsupported.
   
   @XFD::Function::oops::ISA = qw( XFD::BooleanFunction );
sub XFD::Function::oops::as_immed_code { 
    "Carp::confess( 'operator not shorted!' )";
}


## Laid out for wide terminals, sorry.  This code is too tabular to do otherwise

my @tests = (
## Numbers and string literals
sub { d $a,    '0',                                                [ '' ],               '0'         },
## Note: we do not do '-0' in Perl...
sub { d $a,    '-0',                                               [ '' ],               '0'         },
sub { d $a,    '10',                                               [ '' ],               '10'        },
sub { d $a,    '-10',                                              [ '' ],               '-10'       },
sub { d $a,    '""',                                               [ '' ],               ''          },
sub { d $a,    '"string"',                                         [ '' ],               'string'    },

## Functions

sub { d $a,    'concat(boolean(0),"P")',                           [ '' ],               'falseP'    },
sub { d $a,    'concat(boolean(false()),"P")',                     [ '' ],               'falseP'    },
sub { d $a,    'concat(boolean(""),"P")',                          [ '' ],               'falseP'    },
sub { d $a,    'boolean(1)',                                       [ '' ],               'true'      },
sub { d $a,    'boolean(true())',                                  [ '' ],               'true'      },
sub { d $a,    'boolean("0")',                                     [ '' ],               'true'      },
sub { d $a,    'boolean("false")',                                 [ '' ],               'true'      },
sub { d $a,    'ceiling(1)',                                       [ '' ],               '1'         },
sub { d $a,    'ceiling(0.49)',                                    [ '' ],               '1'         },
sub { d $a,    'ceiling(0.999)',                                   [ '' ],               '1'         },
sub { d $a,    'ceiling(-2.999)',                                  [ '' ],               '-2'        },

sub { d $a,    'concat("a","b","c","d")',                          [ '' ],               'abcd'      },
sub { d $a,    'concat(1,2.3)',                                    [ '' ],               '12.3'      },
sub { d $a,    'concat(true(),false())',                           [ '' ],               'truefalse' },

sub { d $a,    'contains("ab","a")',                               [ '' ],               'true'      },
sub { d $a,    'contains("ab","b")',                               [ '' ],               'true'      },

# tested below as a predicate
#sub { d $abcd, 'is-end-event()',                                      \@end_nodes_in_abcd,  'true'      },

sub { d $a,    'string(false())',                                  [ '' ],               'false'     },

sub { d $a,    'concat(floor(0),"P")',                             [ '' ],               '0P'        },
sub { d $a,    'concat(floor(0.5),"P")',                           [ '' ],               '0P'        },
sub { d $a,    'concat(floor(0.999),"P")',                         [ '' ],               '0P'        },
sub { d $a,    'concat(floor(-0.999),"P")',                        [ '' ],               '-1P'       },

sub { d $a,    "normalize-space(' \t\r\na \t\r\nb \t\r\n')",       [ '' ],               'a b'       },

sub { d $a,    'not(0)',                                           [ '' ],               'true'      },
sub { d $a,    'concat(not(1),"P")',                               [ '' ],               'falseP'    },

sub { d $a,    'not(0)',                                           [ '' ],               'true'      },

sub { d $a,    'number(1)',                                        [ '' ],               '1'         },
sub { d $a,    'number(true())',                                   [ '' ],               '1'         },
sub { d $a,    'number(" 1 ")',                                    [ '' ],               '1'         },
sub { d $abc123, 'number(.)',                                      [ '' ],               '123321'    },
sub { d $abc123, 'number()',                                       [ '' ],               '123321'    },
sub { d $ns,   'local-name()',                                     [ '_' ],                          },
sub { d $ns,   'local-name(a)',                                    [ '_a' ],                         },
sub {
    d $ns,   'local-name(//bar:b)',                                [ '_b' ],
    {
        Namespaces => {
            bar => "foo-ns",
        },
    }
},

sub { d $ns,   'name()',                                           [ '_' ],                          },
sub { d $ns,   'name(a)',                                          [ '_a' ],                         },
sub {
    d $ns,   'name(//bar:b)',                                      [ '_foo:b' ],
    {
        Namespaces => {
            bar => "foo-ns",
        },
    }
},

sub { d $ns,   'namespace-uri()',                                  [ '_' ],                          },
sub { d $ns,   'namespace-uri(a)',                                 [ '_default-ns' ],                         },
sub {
    d $ns,   'namespace-uri(//bar:b)',                             [ '_foo-ns' ],
    {
        Namespaces => {
            bar => "foo-ns",
        },
    }
},

sub { d $a,    'concat(round(0),"P")',                             [ '' ],               '0P'        },
sub { d $a,    'concat(round(0.5),"P")',                           [ '' ],               '1P'        },
sub { d $a,    'concat(round(0.999),"P")',                         [ '' ],               '1P'        },
sub { d $a,    'concat(round(-0.999),"P")',                        [ '' ],               '-1P'       },

sub { d $a,    "normalize-space(' \t\r\na \t\r\nb \t\r\n')",       [ '' ],               'a b'       },
sub { d $ab,   'normalize-space(.)',                               [ '' ],               'bA'        },
sub { d $ab,   'normalize-space()',                                [ '' ],               'bA'        },

sub { d $a,    'true()',                                           [ '' ],               'true'      },

sub { d $a,    'starts-with("ab","a")',                            [ '' ],               'true'      },
sub { d $a,    'starts-with("ab","b")',                            [ '' ],               'false'     },

sub { d $a,    'string("a")',                                      [ '' ],               'a'         },
sub { d $a,    'string(true())',                                   [ '' ],               'true'      },
sub { d $a,    'string(01)',                                       [ '' ],               '1'         },

sub { d $a,    'string-length("ab")',                              [ '' ],               '2'         },
sub { d $ab,   'string-length(.)',                                 [ '' ],               '2'         },
sub { d $ab,   'string-length()',                                  [ '' ],               '2'         },

sub { d $a,    'substring("ab",0)',                                [ '' ],               'ab'        },
sub { d $a,    'substring("ab",1)',                                [ '' ],               'ab'        },
sub { d $a,    'substring("ab",2)',                                [ '' ],               'b'         },
sub { d $a,    'concat(substring("ab",3),1)',                      [ '' ],               '1'         },
sub { d $a,    'substring("12345",2,3)',                           [ '' ],               '234'       },
sub { d $a,    'substring("12345",2)',                             [ '' ],               '2345'      },
sub { d $a,    'substring("12345",1.5,2.6)',                       [ '' ],               '234'       },
sub { d $a,    'substring("12345",0,3)',                           [ '' ],               '12'        },
# Perl doesn't handle Inf and NaN right, so...
#sub { d $a,    'substring("12345",0 div 0,3)',                     [ '' ],               'P'         },
#sub { d $a,    'substring("12345",1,0 div 0)',                     [ '' ],               'P'         },
#sub { d $a,    'substring("12345",-42,1 div 0)',                   [ '' ],               '12345'     },
#sub { d $a,    'concat(substring("12345",-1 div 0,1 div 0),"P")',  [ '' ],               'P'         },

sub { d $a,    'substring-after("ab","a")',                        [ '' ],               'b'         },
sub { d $a,    'concat(substring-after("ab","b"),1)',              [ '' ],               '1'         },
sub { d $a,    'concat(substring-after("ab","c"),1)',              [ '' ],               '1'         },
sub { d $a,    'concat(substring-after("ab",""),1)',               [ '' ],               'ab1'       },
sub { d $a,    'substring-after("1999/04/01","19")',               [ '' ],               '99/04/01'  },

sub { d $a,    'substring-before("ab","b")',                       [ '' ],               'a'         },
sub { d $a,    'substring-before("1999/04/01","/")',               [ '' ],               '1999'      },
sub { d $a,    'concat(substring-before("ab","a"),1)',             [ '' ],               '1'         },
sub { d $a,    'concat(substring-before("ab","c"),1)',             [ '' ],               '1'         },
sub { d $a,    'concat(substring-before("ab",""),1)',              [ '' ],               '1'         },

sub { d $a,    'translate("bar","abc","ABC")',                     [ '' ],               'BAr'       },
sub { d $a,    'translate("--aaa--","abc-","ABC")',                [ '' ],               'AAA'       },

## Operators (other than union)
sub { d $a,    'concat( 0 or 0, "P" )',                            [ '' ],               'falseP'    },
sub { d $a,    '0 or 1',                                           [ '' ],               'true'      },
sub { d $a,    '1 or 0',                                           [ '' ],               'true'      },
sub { d $a,    '1 or 1',                                           [ '' ],               'true'      },
sub { d $a,    '1 or oops()',                                      [ '' ],               'true'      },

sub { d $a,    'concat( 0 and 0, "P" )',                           [ '' ],               'falseP'    },
sub { d $a,    'concat( 0 and 1, "P" )',                           [ '' ],               'falseP'    },
sub { d $a,    'concat( 1 and 0, "P" )',                           [ '' ],               'falseP'    },
sub { d $a,    '1 and 1',                                          [ '' ],               'true'      },
sub { d $a,    'concat( 0 and oops(), "P" )',                      [ '' ],               'falseP'    },

sub { d $a,    '0 and 1 or 1',                                     [ '' ],               'true'      },
sub { d $a,    '1 or 1 and 0',                                     [ '' ],               'true'      },

sub { d $a,    'concat( true() = false(), "P" )',                  [ '' ],               'falseP'    },
sub { d $a,    'true() = true()',                                  [ '' ],               'true'      },
sub { d $a,    '1 = 1',                                            [ '' ],               'true'      },
sub { d $a,    '"a" = "a"',                                        [ '' ],               'true'      },
sub { d $a,    '1 = " 1 "',                                        [ '' ],               'true'      },
sub { d $a,    'true() = 1',                                       [ '' ],               'true'      },
sub { d $a,    'false() = 0',                                      [ '' ],               'true'      },
sub { d $a,    'true() = "a"',                                     [ '' ],               'true'      },
sub { d $a,    'false() = ""',                                     [ '' ],               'true'      },

sub { d $a,    'concat( true() != true(), "P" )',                  [ '' ],               'falseP'    },
sub { d $a,    'true() != false()',                                [ '' ],               'true'      },
sub { d $a,    '1 != 0',                                           [ '' ],               'true'      },
sub { d $a,    '"a" != "b"',                                       [ '' ],               'true'      },
sub { d $a,    '1 != " 0 "',                                       [ '' ],               'true'      },
sub { d $a,    'true() != 0',                                      [ '' ],               'true'      },
sub { d $a,    'false() != 1',                                     [ '' ],               'true'      },
sub { d $a,    'true() != ""',                                     [ '' ],               'true'      },
sub { d $a,    'false() != "a"',                                   [ '' ],               'true'      },

sub { d $a,    'concat( true() < true(), "P" )',                   [ '' ],               'falseP'    },
sub { d $a,    'concat( true() < false(), "P" )',                  [ '' ],               'falseP'    },
sub { d $a,    'false() < true()',                                 [ '' ],               'true'      },
sub { d $a,    '0 < 1',                                            [ '' ],               'true'      },
sub { d $a,    '"a" < "b"',                                        [ '' ],               'true'      },
sub { d $a,    '0 < " 1 "',                                        [ '' ],               'true'      },

sub { d $a,    'true() <= true()',                                 [ '' ],               'true'      },
sub { d $a,    'concat( true() <= false(), "P" )',                 [ '' ],               'falseP'    },
sub { d $a,    'false() <= true()',                                [ '' ],               'true'      },
sub { d $a,    '0 <= 1',                                           [ '' ],               'true'      },
sub { d $a,    '"a" <= "b"',                                       [ '' ],               'true'      },
sub { d $a,    '0 <= " 1 "',                                       [ '' ],               'true'      },

sub { d $a,    'concat( true() > true(), "P" )',                   [ '' ],               'falseP'    },
sub { d $a,    'concat( false() > true(), "P" )',                  [ '' ],               'falseP'    },
sub { d $a,    'true() > false()',                                 [ '' ],               'true'      },
sub { d $a,    '1 > 0',                                            [ '' ],               'true'      },
sub { d $a,    '"b" > "a"',                                        [ '' ],               'true'      },
sub { d $a,    '1 > " 0 "',                                        [ '' ],               'true'      },
sub { d $a,    'concat( 3 > 2 > 1, "P" )',                         [ '' ],               'falseP'    },

sub { d $a,    'true() >= true()',                                 [ '' ],               'true'      },
sub { d $a,    'concat( false() >= true(), "P" )',                 [ '' ],               'falseP'    },
sub { d $a,    'true() >= false()',                                [ '' ],               'true'      },
sub { d $a,    '1 >= 0',                                           [ '' ],               'true'      },
sub { d $a,    '"b" >= "a"',                                       [ '' ],               'true'      },
sub { d $a,    '1 >= " 0 "',                                       [ '' ],               'true'      },

sub { d $a,    '4 + 1',                                            [ '' ],               '5'         },
sub { d $a,    '4 - 1',                                            [ '' ],               '3'         },
sub { d $a,    '4 * 1',                                            [ '' ],               '4'         },
sub { d $a,    '4 div 2',                                          [ '' ],               '2'         },
sub { d $a,    '5 mod 2',                                          [ '' ],               '1'         },

sub { d $a,    '( 1 )',                                            [ '' ],               '1'         },
sub { d $a,    '- ( 1 )',                                          [ '' ],               '-1'        },

##
## Location paths
##
sub { d $abcd, '/',                                                [ '' ]                            },
sub { d $abcd, '/.',                                               [ '' ]                            },
sub { d $abcd, '/child::a',                                        [ 'a' ]                           },
sub { d $abcd, '/a',                                               [ 'a' ]                           },
sub { d $abcd, 'a',                                                [ 'a' ]                           },
sub { d $abcd, './a',                                              [ 'a' ]                           },
sub { d $abcd, '.',                                                [ '']                             },
sub { d $abcd, '//b',                                              [ 'b' ]                           },
sub { d $abcd, 'b',                                                [ 'b' ]                           },
sub { d $abcd, '//./b',                                            [ 'b' ]                           },
sub { d $abcd, 'd',                                                [ 'd', 'd' ]                      },
## This next one tests to make sure 'b' doesn't fire twice
sub { d $abcd, '//.//b',                                           [ 'b' ]                           },
sub { d $abcd, '/a/b/c',                                           [ 'c' ]                           },
sub { d $abcd, '/a/b/c/d',                                         [ 'd', 'd' ]                      },
sub { d $abcd, '(((/a)/b)/c)/d',                                   [ 'd', 'd' ]                      },
##sub { d $abcd, '/*',                                               [ 'a' ]                           },
sub { d $abcd, '/child::*',                                        [ 'a' ]                           },
sub { d $abcd, '/*/child::*',                                      [ 'b' ]                           },
sub { d $abcd, '*',                                                [ 'a', 'b', 'c', 'd', 'd' ]       },

##
## //descendant-or-self::node()
##
sub { d $abcd, '/descendant-or-self::node()',                      \@non_attr_nodes_in_abcd          },

sub { d $abcd, '/descendant-or-self::node()/node()',               [ @non_attr_nodes_in_abcd[ 1..$#non_attr_nodes_in_abcd ] ] },
sub { d $abcd, '//node()',                                         [ @non_attr_nodes_in_abcd[ 1..$#non_attr_nodes_in_abcd ] ] },
sub { d $abcd, '/descendant-or-self::node()/a',                    [ 'a' ]                           },
sub { d $abcd, '//a',                                              [ 'a' ]                           },
sub { d $abcd, '/descendant-or-self::node()/b',                    [ 'b' ]                           },
sub { d $abcd, '//b',                                              [ 'b' ]                           },
sub { d $abcd, '/descendant-or-self::node()/d',                    [ 'd', 'd' ]                      },
sub { d $abcd, '//d',                                              [ 'd', 'd' ]                      },
sub { d $abcdBcd, '/a/B//d',                                       [ 'd', 'd' ]                      },

## TODO: fix grammar to like ////
#sub { d $abcd, '////node()',                                                                [ @non_attr_nodes_in_abcd[ 1..$#non_attr_nodes_in_abcd ] ] },
sub { d $abcd, '/descendant-or-self::node()/descendant-or-self::node()/node()',              [ @non_attr_nodes_in_abcd[ 1..$#non_attr_nodes_in_abcd ] ] },

sub { d $abcd, '/self::node()',                                    [ '' ]                            },
sub { d $abcd, '/self::node()/a',                                  [ 'a' ]                           },
sub { d $abcd, '/./a',                                             [ 'a' ]                           },
sub { d $abcd, '//./a',                                            [ 'a' ]                           },
sub { d $abcd, '//./d',                                            [ 'd', 'd' ]                      },

sub { d $abcd, '//attribute::id',                                  [ 'id', 'id' ]                    },
sub { d $abcd, '//@id',                                            [ 'id', 'id' ]                    },
sub { d $abcd, '@id',                                              [ 'id', 'id' ]                    },
sub { d $abcd, '//attribute::*',                                   [ 'id', 'name', 'id' ]            },
sub { d $abcd, '//@*',                                             [ 'id', 'name', 'id' ]            },
## Node tests (other than node())
sub { d $abcd, '//text()',                                         [qw( s t u v w x y z )]           },
sub { d $abcd, '//comment()',                                      [qw( R S T Z1 )]                  },
sub { d $abcd, '//processing-instruction()',                       [qw( RRrr SSss TTtt Z1Z1z1z1 )]   },

## Union: |
sub { d $abcd, '//a|//b',                                          [ 'a', 'b' ]                      },
sub { d $abcd, 'a|b',                                              [ 'a', 'b' ]                      },
sub { d $abcd, '//a|//a',                                          [ 'a' ]                           },
sub { d $abcd, '//a|//a|//a',                                      [ 'a' ]                           },
sub { d $abcdBcd, '/a/b/c|/a/B/c',                                 [ 'c', 'c' ]                      },
sub { d $abcdBcd, '(/a/b|/a/B)/c',                                 [ 'c', 'c' ]                      },
## Predicates
## TODO: sub { d $a, 'a[b]/b[c]', [ 'b' ] },
sub { d $a,    'a[1]',                                             [ 'a' ]                           },
sub { d $a,    'a[0]',                                             []                                },
sub { d $abcd, '//d[@id]',                                         [ 'd', 'd' ],                     },
sub { d $abcd, '//d[@id=1]',                                       [ 'd' ],                          },
sub { d $abcd, 'a[b]',                                             [ 'a' ]                           },
sub { d $abcd, 'a[c]',                                             []                                },
#sub { Devel::TraceCalls::trace_calls( "XML::Filter::Dispatcher->" ) },
sub { d $abcd, 'a[b]/b',                                           [ 'b' ]                           },
sub { d $abcd, 'a[b]/b/c/d',                                       [ 'd', 'd' ]                      },
sub { d $abcd, 'a[c]/b/c/d',                                       []                                },
## Functions that take node sets (and thus require precursors)
sub { d $ab,   'string(a)',                                        [ '_bA' ]                         },
sub { d $abcd, 'string(.)',                                        [ '_stuvwxyz' ]                   },
sub { d $abcd, 'string()',                                         [ '_stuvwxyz' ]                   },
sub { d $abcd, 'string(//text())',                                 [ '_s' ]                          },
sub { d $abcd, 'string(//comment())',                              [ '_R' ]                          },
sub { d $abcd, 'string(//processing-instruction())',               [ '_rr' ],                        },
sub { d $ab,   'string(a/b)',                                      [ '_b' ]                          },
sub { d $ab,   'string(b)',                                        [ '_' ]                           },
sub { d $abcd, 'string(a/b/c/d)',                                  [ '_v' ],                         },
sub { d $abcd, 'string(//d)',                                      [ '_v' ],                         },
sub { d $abcd, 'string(//@id)',                                    [ '_1' ],                         },
sub { d $abcd, 'concat(//@id, "")',                                [ '_1' ],                         },

sub { d $a,    'boolean(a)',                                      [ '' ],                'true'      },
sub { d $a,    'boolean(b)',                                      [ '' ],                'false'     },
sub { d $abcd, 'boolean(a/b)',                                    [ '' ],                'true'      },
sub { d $abcd, 'boolean(a/b/c/d)',                                [ '' ],                'true'      },
sub { d $abcd, 'boolean(//@id)',                                  [ '' ],                'true'      },
sub { d $a,    'not(a)',                                          [ '' ],                'false'     },
sub { d $abcd, 'not(a/b/c/d)',                                    [ '' ],                'false'     },
sub { d $a,    'not(b)',                                          [ '' ],                'true'      },

sub { d $abc123, 'number(/a)',                                     [ '' ],                '123321'   },
sub { d $abc123, 'number(/a/b)',                                   [ '' ],                '2332'     },
sub { d $abc123, 'number(//c)',                                    [ '_3' ],                         },
sub { d $abc123, 'number(//@id)',                                  [ '_10' ],                        },
sub { d $abc123, '- //@id',                                        [ '_-10' ],                       },
## Multiple precursors
sub { d $ab,   'concat( //@id, //@id )',                           [ '_11' ],                        },
sub { d $ab,   'concat( //@id, //@name )',                         [ '_1joe' ],                      },
sub { d $ab,   'string(a | a/b)',                                  [ '_bA' ]                         },
sub { d $ab,   'string(c | a/b)',                                  [ '_b' ]                          },
sub { d $ab,   'concat( string(a), ":", string(a) )',              [ '_bA:bA' ],                     },
sub { d $ab,   'concat( string(a), ":", string(a/b) )',            [ '_bA:b' ],                      },
sub { d $ab,   'concat( string(a), ":", string(@id) )',            [ '_bA:' ],                       },
sub { d $ab,   'concat( string(a), ":", string(a/b/@id) )',        [ '_bA:1' ],                      },
sub { d $ab,   'concat( string(a), ":", string(a//@id) )',         [ '_bA:1' ],                      },
## Variable references
sub { d $var,   'concat( $foo, "!" )',                             [ '' ],                'true!'    },
## Nested rules
sub { d $abcd, [ 'a'    => [ 'b' ] ],                              [ 'b' ]                           },
sub { d $abcd, [ 'a[b]' => [ 'b' ] ],                              [ 'b' ]                           },
sub { d $abcd, [ a => [ 'b', b => [ 'c' ] ] ],                     [ 'b', 'c' ]                      },
sub { d $abcd, [ a => [ b => [ c => [ "string( d )" ] ] ] ],       [ 'c_v' ]                         },
sub { d $abcd, [ 'a/b' => [ c => [ "string( d )" ] ] ],            [ 'c_v' ]                         },
sub { d $abcd, [ 'a/b/c' => [ "string( d )" ] ],                   [ 'c_v' ]                         },
sub { d $abcdBcd, [ 'a/b/c' => [ "string( d )" ] ],                [ 'c_1' ]                         },
sub { d $abcdBcd, [ 'a/b/c|a/B/c' => [ "string( d )" ] ],          [ 'c_1', 'c_3' ]                  },

## Postponement

sub { d $aaaabaa, '//a[b]',                                          [ 'a' ]                 },
sub { d $aaaabaa, '//a[b]/a',                                        [ 'a', 'a' ]            },
sub { d $aaaabaa, '//a[b]//a',                                       [ 'a', 'a', 'a' ]       },

sub { d $aaaaaab, '//a[b]',                                          [ 'a' ]                 },
sub { d $aaaaaab, '//a[b]/a',                                        [ 'a', 'a' ]            },
sub { d $aaaaaab, '//a[b]//a',                                       [ 'a', 'a', 'a' ]       },
sub { d $aaacb,   '//a[b]//a[c]//a',                                 [ 'a' ]                 },
sub { d $aaaacb,  '//a[b]//a[c]//a',                                 [ 'a', 'a' ]            },

## SAX axes

sub { d $ab,      '/end-document::*',                                [ '' ]                  },
sub { d $ab,      '/a/end-element::b',                               [ 'b' ]                 },
sub { d $ab,      '/a/end::b',                                       [ 'b' ]                 },
sub { d $ab,      '/a[b]/end-element::b',                            [ 'b' ]                 },
sub { d $abcdBcd, '/a[b]/end-element::b',                            [ 'b' ]                 },
sub { d $abcdBcd, '/a[b]/end-element::B',                            [ 'B' ]                 },
sub { d $abcdBcd, '/a[B]/end-element::b',                            [ 'b' ]                 },

sub { d $ab,      '/a/start-element::b',                             [ 'b' ]                 },
sub { d $ab,      '/a/start::b',                                     [ 'b' ]                 },
sub { d $ab,      '/start-document::*',                              [ '' ]                  },

## Namespace tests
sub { d $ns,   'local-name(a)',                                    [ '_a' ],
},
sub { d $ns,   'local-name(a)',                                    [ '_a' ], 
    {
        Namespaces => {
            "" => "default-ns",
            bar => "foo-ns",
        },
    }
},
sub { d $ns,   'local-name(bar:a)',                                [ '_a' ], 
    {
        Namespaces => {
            bar => "default-ns",
        },
    }
},
sub {
    d $ns,   'local-name(//b)',                                    [ '_b' ],
    {
        Namespaces => {
            "" => "foo-ns",
        },
    }
},
sub {
    d $ns,   'local-name(//bar:*)',                                    [ '_a' ],
    {
        Namespaces => {
            ""    => "default-ns",
            "bar" => "default-ns",
        },
    }
},
sub {
    d $ns,   'local-name(//bar:*)',                                    [ '_b' ],
    {
        Namespaces => {
            "bar" => "foo-ns",
        },
    }
},

##
## Some more complex expressions
##
sub { d $ab, 'string( //b )',     ['_b']  },
sub { d $ab, 'string( //* )',     ['_bA'] },
sub { d $ab, '//*[*]',            ['a'] },
sub { d $ab, '//*[not(*)]',       ['b'] },
#sub { d $ab, [ "//*[not(*)]" => [ "string()" ] ],   [ 'b_b' ]       },  ## TODO
);

plan tests => 2 * @tests;

for ( @tests ) {
    $fold_constants = 0;
    $_->();
    $fold_constants = 1;
    $_->();
}

## This quick little buffering filter is used to save us the overhead
## of a parse for each test.  This saves me sanity (since I run the test
## suite a lot), allows me to see which tests are noticably slower in
## case something pathalogical happens, and keeps admins from getting the
## impression that this is a slow package based on test suite speed.
package QB;
use vars qw( $AUTOLOAD );
use File::Basename;

sub new {
    my $self = bless [], shift;

    my ( $name, $doc ) = @_;

    my $cache_fn = basename( $0 ) . ".cache.$name";
    if ( -e $cache_fn && -M $cache_fn < -M $0 ) {
        my $old_self = do $cache_fn;
        return $old_self if defined $old_self;
        warn "$!$@";
        unlink $cache_fn;
    }

    require XML::SAX::PurePerl; ## Cannot use ParserFactory; LibXML 1.31 is broken.
    require Data::Dumper;
    my $p = XML::SAX::PurePerl->new( Handler => $self );
    $p->parse_string( $doc );
    if ( open F, ">$cache_fn" ) {
        local $Data::Dumper::Terse;
        $Data::Dumper::Terse = 1;
        print F Data::Dumper::Dumper( $self );
        close F;
    }

    return $self;
}

sub DESTROY;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*://;
    if ( $AUTOLOAD eq "start_element" ) {
        ## Older (and mebbe newer :) X::S::PurePerls reuse the same
        ## hash in end_element but delete the Attributes, so we need
        ## to copy.  And I can't copy everything because some other
        ## overly magical thing dies, haven't tracked down beyond seeing
        ## signs that it's XML::SAX::DocumentLocator::NEXTKEY(/usr/local/lib/perl5/site_perl/5.6.1/XML/SAX/DocumentLocator.pm:72)
        ## but I hear that's fixed in CVS :).
        push @$self, [ $AUTOLOAD, [ { %{$_[0]} } ] ];
    }
    else {
        push @$self, [ $AUTOLOAD, [ $_[0] ] ];
    }
}

sub playback {
    my $self = shift;
    my $h = shift;
    for ( @$self ) {
        my $m = $_->[0];
        no strict "refs";
        $h->$m( @{$_->[1]} );
    }
}
