####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package yagg::NonterminalParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "etc/nonterminal_parser_grammar.yp"

# (c) Copyright David Coppit 2004, all rights reserved.
# (see COPYRIGHT in yagg documentation for use and distribution
# rights)
#
# Written by David Coppit <david@coppit.org>
#
# This grammar is based on that of Bison 1.05. I've left out undocumented
# features, and definitions that are unused. A version of this file was
# submitted to Francois Desarmenien, the author of Parse::Yapp. Hopefully he
# will decide to use it to update his grammar parser.
#
# Use: yapp -m 'yagg::NonterminalParser' -o lib/yagg/NonterminalParser.pm etc/nonterminal_parser_grammar.yp
#
# to generate the Parser module.
# 
#line 19 "etc/nonterminal_parser_grammar.yp"

require 5.004;

use Carp;

my($input,$lexlevel,@lineno,$nberr,$prec,$precedences,$labelno);
my($syms,$declarations,$epilogue,$token,$term,$nterm,$rules,$precterm,$start,$nullable,$aliases);
my($expect);



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		DEFAULT => -3,
		GOTOS => {
			'input' => 1,
			'declarations' => 2
		}
	},
	{#State 1
		ACTIONS => {
			'' => 3
		}
	},
	{#State 2
		ACTIONS => {
			'PERCENT_YACC' => 29,
			'PERCENT_PURE_PARSER' => 28,
			'PERCENT_OUTPUT' => 31,
			'PERCENT_START' => 30,
			'PERCENT_TOKEN_TABLE' => 21,
			'PERCENT_NAME_PREFIX' => 20,
			'PERCENT_NO_LINES' => 19,
			"%%" => 27,
			'PERCENT_TOKEN' => 24,
			'PROLOGUE' => 25,
			'PERCENT_DEBUG' => 23,
			'PERCENT_FILE_PREFIX' => 22,
			'PERCENT_NONASSOC' => 13,
			'PERCENT_LEFT' => 12,
			'PERCENT_EXPECT' => 16,
			'PERCENT_VERBOSE' => 15,
			'PERCENT_RIGHT' => 14,
			'SEMICOLON' => 5,
			'PERCENT_DEFINES' => 4,
			'PERCENT_TYPE' => 6,
			'PERCENT_PARSE_PARAM' => 7,
			'PERCENT_UNION' => 8,
			'PERCENT_LOCATIONS' => 10
		},
		GOTOS => {
			'declaration' => 17,
			'symbol_declaration' => 18,
			'precedence_declaration' => 9,
			'grammar_declaration' => 11,
			'precedence_declarator' => 26
		}
	},
	{#State 3
		DEFAULT => 0
	},
	{#State 4
		DEFAULT => -8
	},
	{#State 5
		DEFAULT => -20
	},
	{#State 6
		ACTIONS => {
			'TYPE' => 32
		}
	},
	{#State 7
		DEFAULT => -15
	},
	{#State 8
		ACTIONS => {
			'BRACED_CODE' => 33
		}
	},
	{#State 9
		DEFAULT => -21
	},
	{#State 10
		DEFAULT => -11
	},
	{#State 11
		DEFAULT => -5
	},
	{#State 12
		DEFAULT => -29
	},
	{#State 13
		DEFAULT => -31
	},
	{#State 14
		DEFAULT => -30
	},
	{#State 15
		DEFAULT => -18
	},
	{#State 16
		ACTIONS => {
			'INT' => 34
		}
	},
	{#State 17
		DEFAULT => -4
	},
	{#State 18
		DEFAULT => -22
	},
	{#State 19
		DEFAULT => -13
	},
	{#State 20
		ACTIONS => {
			'EQUAL' => 35
		}
	},
	{#State 21
		DEFAULT => -17
	},
	{#State 22
		ACTIONS => {
			'EQUAL' => 36
		}
	},
	{#State 23
		DEFAULT => -7
	},
	{#State 24
		ACTIONS => {
			'IDENT' => 39,
			'TYPE' => 38
		},
		GOTOS => {
			'symbol_def' => 37,
			'ID' => 40,
			'symbol_defs_1' => 41
		}
	},
	{#State 25
		DEFAULT => -6
	},
	{#State 26
		ACTIONS => {
			'TYPE' => 42
		},
		DEFAULT => -32,
		GOTOS => {
			'type_opt' => 43
		}
	},
	{#State 27
		ACTIONS => {
			'ID_COLON' => 48,
			'ERROR' => 47,
			'SEMICOLON' => 46
		},
		DEFAULT => -2,
		GOTOS => {
			'rules_or_grammar_declaration' => 45,
			'rules' => 44,
			'grammar' => 49
		}
	},
	{#State 28
		DEFAULT => -16
	},
	{#State 29
		DEFAULT => -19
	},
	{#State 30
		ACTIONS => {
			'STRING' => 50,
			'IDENT' => 39
		},
		GOTOS => {
			'ID' => 52,
			'string_as_id' => 53,
			'symbol' => 51
		}
	},
	{#State 31
		DEFAULT => -14
	},
	{#State 32
		ACTIONS => {
			'STRING' => 50,
			'IDENT' => 39
		},
		GOTOS => {
			'symbol' => 54,
			'symbols_1' => 55,
			'ID' => 52,
			'string_as_id' => 53
		}
	},
	{#State 33
		DEFAULT => -24
	},
	{#State 34
		DEFAULT => -9
	},
	{#State 35
		ACTIONS => {
			'STRING' => 57
		},
		GOTOS => {
			'string_content' => 56
		}
	},
	{#State 36
		ACTIONS => {
			'STRING' => 57
		},
		GOTOS => {
			'string_content' => 58
		}
	},
	{#State 37
		DEFAULT => -40
	},
	{#State 38
		ACTIONS => {
			'IDENT' => 39
		},
		GOTOS => {
			'ID' => 40,
			'symbol_def' => 37,
			'symbol_defs_1' => 59
		}
	},
	{#State 39
		DEFAULT => -64
	},
	{#State 40
		ACTIONS => {
			'INT' => 60,
			'STRING' => 50
		},
		DEFAULT => -36,
		GOTOS => {
			'string_as_id' => 61
		}
	},
	{#State 41
		ACTIONS => {
			'IDENT' => 39
		},
		DEFAULT => -25,
		GOTOS => {
			'symbol_def' => 62,
			'ID' => 40
		}
	},
	{#State 42
		DEFAULT => -33
	},
	{#State 43
		ACTIONS => {
			'IDENT' => 39,
			'STRING' => 50
		},
		GOTOS => {
			'string_as_id' => 53,
			'ID' => 52,
			'symbols_1' => 63,
			'symbol' => 54
		}
	},
	{#State 44
		DEFAULT => -44
	},
	{#State 45
		DEFAULT => -42
	},
	{#State 46
		DEFAULT => -47
	},
	{#State 47
		ACTIONS => {
			'IDENT' => 39,
			'STRING' => 50,
			'SEMICOLON' => 65
		},
		GOTOS => {
			'symbol' => 64,
			'ID' => 52,
			'string_as_id' => 53
		}
	},
	{#State 48
		DEFAULT => -51,
		GOTOS => {
			'rhses_1' => 66,
			'rhs' => 67
		}
	},
	{#State 49
		ACTIONS => {
			'SEMICOLON' => 46,
			"%%" => 68,
			'ID_COLON' => 48,
			'ERROR' => 47
		},
		DEFAULT => -62,
		GOTOS => {
			'rules' => 44,
			'rules_or_grammar_declaration' => 70,
			'epilogue_opt' => 69
		}
	},
	{#State 50
		DEFAULT => -60
	},
	{#State 51
		DEFAULT => -23
	},
	{#State 52
		DEFAULT => -55
	},
	{#State 53
		DEFAULT => -56
	},
	{#State 54
		DEFAULT => -34
	},
	{#State 55
		ACTIONS => {
			'STRING' => 50,
			'IDENT' => 39
		},
		DEFAULT => -27,
		GOTOS => {
			'string_as_id' => 53,
			'ID' => 52,
			'symbol' => 71
		}
	},
	{#State 56
		DEFAULT => -12
	},
	{#State 57
		DEFAULT => -61
	},
	{#State 58
		DEFAULT => -10
	},
	{#State 59
		ACTIONS => {
			'IDENT' => 39
		},
		DEFAULT => -26,
		GOTOS => {
			'ID' => 40,
			'symbol_def' => 62
		}
	},
	{#State 60
		ACTIONS => {
			'STRING' => 50
		},
		DEFAULT => -37,
		GOTOS => {
			'string_as_id' => 72
		}
	},
	{#State 61
		DEFAULT => -38
	},
	{#State 62
		DEFAULT => -41
	},
	{#State 63
		ACTIONS => {
			'IDENT' => 39,
			'STRING' => 50
		},
		DEFAULT => -28,
		GOTOS => {
			'ID' => 52,
			'string_as_id' => 53,
			'symbol' => 71
		}
	},
	{#State 64
		ACTIONS => {
			'SEMICOLON' => 73
		}
	},
	{#State 65
		DEFAULT => -46
	},
	{#State 66
		ACTIONS => {
			'PIPE' => 74
		},
		DEFAULT => -48
	},
	{#State 67
		ACTIONS => {
			'BRACED_CODE_WITH_BRACED_CODE_FOLLOWING' => 78,
			'IDENT' => 39,
			'BRACED_CODE' => -57,
			'STRING' => 50,
			'PERCENT_PREC' => 76
		},
		DEFAULT => -49,
		GOTOS => {
			'ID' => 52,
			'action_opt' => 77,
			'string_as_id' => 53,
			'symbol' => 75
		}
	},
	{#State 68
		ACTIONS => {
			'EPILOGUE' => 79
		}
	},
	{#State 69
		DEFAULT => -1
	},
	{#State 70
		DEFAULT => -43
	},
	{#State 71
		DEFAULT => -35
	},
	{#State 72
		DEFAULT => -39
	},
	{#State 73
		DEFAULT => -45
	},
	{#State 74
		DEFAULT => -51,
		GOTOS => {
			'rhs' => 80
		}
	},
	{#State 75
		DEFAULT => -52
	},
	{#State 76
		ACTIONS => {
			'IDENT' => 39,
			'STRING' => 50
		},
		GOTOS => {
			'symbol' => 81,
			'ID' => 52,
			'string_as_id' => 53
		}
	},
	{#State 77
		ACTIONS => {
			'BRACED_CODE' => 82
		},
		GOTOS => {
			'action' => 83
		}
	},
	{#State 78
		DEFAULT => -58
	},
	{#State 79
		DEFAULT => -63
	},
	{#State 80
		ACTIONS => {
			'STRING' => 50,
			'BRACED_CODE' => -57,
			'BRACED_CODE_WITH_BRACED_CODE_FOLLOWING' => 78,
			'IDENT' => 39,
			'PERCENT_PREC' => 76
		},
		DEFAULT => -50,
		GOTOS => {
			'symbol' => 75,
			'string_as_id' => 53,
			'action_opt' => 77,
			'ID' => 52
		}
	},
	{#State 81
		DEFAULT => -54
	},
	{#State 82
		DEFAULT => -59
	},
	{#State 83
		DEFAULT => -53
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'input', 4,
sub
#line 74 "etc/nonterminal_parser_grammar.yp"
{
                    $start
                or  $start=$$rules[1][0];

                    ref($$nterm{$start})
                or  _SyntaxError(2,"Start symbol $start not found ".
                                   "in rules section",$_[4][1]);

                $$rules[0]=[ '$start', [ $start, chr(0) ], undef, undef ];
            }
	],
	[#Rule 2
		 'input', 2,
sub
#line 85 "etc/nonterminal_parser_grammar.yp"
{ _SyntaxError(2,"No rules in input grammar",$_[2][1]); }
	],
	[#Rule 3
		 'declarations', 0, undef
	],
	[#Rule 4
		 'declarations', 2, undef
	],
	[#Rule 5
		 'declaration', 1, undef
	],
	[#Rule 6
		 'declaration', 1,
sub
#line 100 "etc/nonterminal_parser_grammar.yp"
{ push(@$declarations,$_[1]); undef }
	],
	[#Rule 7
		 'declaration', 1,
sub
#line 101 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%debug\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 8
		 'declaration', 1,
sub
#line 105 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%defines\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 9
		 'declaration', 2,
sub
#line 109 "etc/nonterminal_parser_grammar.yp"
{ $expect=$_[2][0]; undef }
	],
	[#Rule 10
		 'declaration', 3,
sub
#line 110 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%file-prefix\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 11
		 'declaration', 1,
sub
#line 114 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%locations\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 12
		 'declaration', 3,
sub
#line 118 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%name-prefix\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 13
		 'declaration', 1,
sub
#line 122 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%no-lines\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 14
		 'declaration', 1,
sub
#line 126 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%output\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 15
		 'declaration', 1,
sub
#line 130 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%parse-param\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 16
		 'declaration', 1,
sub
#line 134 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%pure-parser\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 17
		 'declaration', 1,
sub
#line 138 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%token-table\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 18
		 'declaration', 1,
sub
#line 142 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%verbose\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 19
		 'declaration', 1,
sub
#line 146 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"Parser option \"\%yacc\" is not supported. ".
                     "It will be ignored",$_[1][1]);
                                           }
	],
	[#Rule 20
		 'declaration', 1, undef
	],
	[#Rule 21
		 'grammar_declaration', 1, undef
	],
	[#Rule 22
		 'grammar_declaration', 1, undef
	],
	[#Rule 23
		 'grammar_declaration', 2,
sub
#line 157 "etc/nonterminal_parser_grammar.yp"
{
      $start=$_[2][0]; undef
    }
	],
	[#Rule 24
		 'grammar_declaration', 2,
sub
#line 161 "etc/nonterminal_parser_grammar.yp"
{
      undef
    }
	],
	[#Rule 25
		 'symbol_declaration', 2,
sub
#line 168 "etc/nonterminal_parser_grammar.yp"
{
                for (@{$_[2]}) {
                    my($symbol,$lineno)=@$_;

                        exists($$token{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Token $symbol redefined: ".
                                "Previously defined line $$token{$symbol}",
                                $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                }
                undef
            }
	],
	[#Rule 26
		 'symbol_declaration', 3,
sub
#line 186 "etc/nonterminal_parser_grammar.yp"
{
                for (@{$_[3]}) {
                    my($symbol,$lineno)=@$_;

                        exists($$token{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Token $symbol redefined: ".
                                "Previously defined line $$token{$symbol}",
                                $lineno);
                        next;
                    };
                    $$token{$symbol}=$lineno;
                    $$term{$symbol} = [ ];
                }
                undef
            }
	],
	[#Rule 27
		 'symbol_declaration', 3,
sub
#line 204 "etc/nonterminal_parser_grammar.yp"
{
                for ( @{$_[3]} ) {
                    my($symbol,$lineno)=@$_;

                        exists($$nterm{$symbol})
                    and do {
                        _SyntaxError(0,
                                "Non-terminal $symbol redefined: ".
                                "Previously defined line $$nterm{$symbol}",
                                $lineno);
                        next;
                    };
                    delete($$term{$symbol});   #not a terminal
                    $$nterm{$symbol}=undef;    #is a non-terminal
                }
            }
	],
	[#Rule 28
		 'precedence_declaration', 3,
sub
#line 224 "etc/nonterminal_parser_grammar.yp"
{
      for (@{$_[3]}) {
          my($symbol,$lineno)=@$_;

              defined($$precedences{$symbol})
          and do {
              _SyntaxError(1,
                  "Precedence for symbol $symbol redefined: ".
                  "Previously defined line $$precedences{$symbol}",
                  $lineno);
              next;
          };
          $$token{$symbol}=$lineno;
          $$term{$symbol} = [ $_[1][0], $prec ];
          $$precedences{$symbol} = $prec;
      }
      ++$prec;
      undef
    }
	],
	[#Rule 29
		 'precedence_declarator', 1, undef
	],
	[#Rule 30
		 'precedence_declarator', 1, undef
	],
	[#Rule 31
		 'precedence_declarator', 1, undef
	],
	[#Rule 32
		 'type_opt', 0, undef
	],
	[#Rule 33
		 'type_opt', 1, undef
	],
	[#Rule 34
		 'symbols_1', 1,
sub
#line 259 "etc/nonterminal_parser_grammar.yp"
{ [ $_[1] ] }
	],
	[#Rule 35
		 'symbols_1', 2,
sub
#line 260 "etc/nonterminal_parser_grammar.yp"
{ push(@{$_[1]},$_[2]); $_[1] }
	],
	[#Rule 36
		 'symbol_def', 1, undef
	],
	[#Rule 37
		 'symbol_def', 2,
sub
#line 267 "etc/nonterminal_parser_grammar.yp"
{
      _SyntaxError(0,"User-defined numeric token codes are not supported. ".
                     "The value \"$_[2][0]\" will be ignored",$_[2][1]);
      $_[1];
    }
	],
	[#Rule 38
		 'symbol_def', 2,
sub
#line 273 "etc/nonterminal_parser_grammar.yp"
{
      $$aliases{$_[2][0]} = $_[1][0];
      delete $$term{$_[2][0]};
      $_[1];
    }
	],
	[#Rule 39
		 'symbol_def', 3,
sub
#line 279 "etc/nonterminal_parser_grammar.yp"
{
      $$aliases{$_[3][0]} = $_[1][0];
      delete $$term{$_[3][0]};
      _SyntaxError(0,"User-defined numeric token codes are not supported. ".
                     "The value \"$_[2][0]\" will be ignored",$_[2][1]);
      $_[1];
    }
	],
	[#Rule 40
		 'symbol_defs_1', 1,
sub
#line 291 "etc/nonterminal_parser_grammar.yp"
{ [ $_[1] ] }
	],
	[#Rule 41
		 'symbol_defs_1', 2,
sub
#line 293 "etc/nonterminal_parser_grammar.yp"
{ push(@{$_[1]},$_[2]); $_[1]; }
	],
	[#Rule 42
		 'grammar', 1, undef
	],
	[#Rule 43
		 'grammar', 2, undef
	],
	[#Rule 44
		 'rules_or_grammar_declaration', 1, undef
	],
	[#Rule 45
		 'rules_or_grammar_declaration', 3,
sub
#line 318 "etc/nonterminal_parser_grammar.yp"
{
      $_[0]->YYErrok
    }
	],
	[#Rule 46
		 'rules_or_grammar_declaration', 2,
sub
#line 322 "etc/nonterminal_parser_grammar.yp"
{
      $_[0]->YYErrok
    }
	],
	[#Rule 47
		 'rules_or_grammar_declaration', 1, undef
	],
	[#Rule 48
		 'rules', 2,
sub
#line 330 "etc/nonterminal_parser_grammar.yp"
{
      # For some reason Parse::Yapp treats the last code array as a
      # non-reference. i.e. instead of
      # [ ['SYMB',...], ['BRACED_CODE',...], ['SYMB',...], ['BRACED_CODE',['x',4]] ]
      # it has
      # [ ['SYMB',...], ['BRACED_CODE',...], ['SYMB',...], 'x',4 ]

      my $code;

      for(my $i=0;$i<=$#{$_[2]};$i++)
      {
        unless (defined $_[2][$i])
        {
          splice(@{$_[2]},$i,1,[undef,undef]);
          next;
        }

        # Get the precedence, if any
        my $precedence = undef;

        for(my $j=0;$j<=$#{$_[2][$i]};$j++)
        {
          if ($_[2][$i][$j][0] eq 'PERCENT_PREC')
          {
            if(defined $precedence)
            {
              _SyntaxError(2,"\%prec can only appear once in a rule", $_[1][1]);
            }
            else
            {
              $precedence = $_[2][$i][$j][1];
              splice(@{$_[2][$i]},$j,1),
            }
          }
        }

        # Dereference last code block
        my $code_block_found = 0;

        if(@{$_[2][$i]} >= 1)
        {
          if ($_[2][$i][-1][0] eq 'BRACED_CODE')
          {
            $code_block_found = 1;
            # Merge the lists if there was an unaction block too. (We
            # need to make sure we do this in a way that doesn't freak
            # Parse::Yapp out.)
            my @code_and_line_numbers = @{ $_[2][$i][-1][1] };
            push @code_and_line_numbers, @{ $_[2][$i][-1][2] }
              if defined $_[2][$i][-1][2];
            splice(@{$_[2][$i]},-1,1,($precedence,\@code_and_line_numbers));
          }
        }

        # Append undef, undef if no code block was found
        push @{$_[2][$i]}, $precedence, undef unless $code_block_found;

        for(my $j=0;$j<=$#{$_[2][$i]}-2;$j++)
        {
          $_[2][$i][$j][0] = 'CODE' if $_[2][$i][$j][0] eq 'BRACED_CODE';
        }
      }

      _AddRules($_[1],$_[2]);
      undef;
    }
	],
	[#Rule 49
		 'rhses_1', 1,
sub
#line 399 "etc/nonterminal_parser_grammar.yp"
{ [ $_[1] ] }
	],
	[#Rule 50
		 'rhses_1', 3,
sub
#line 400 "etc/nonterminal_parser_grammar.yp"
{ push(@{$_[1]},$_[3]); $_[1] }
	],
	[#Rule 51
		 'rhs', 0,
sub
#line 405 "etc/nonterminal_parser_grammar.yp"
{ }
	],
	[#Rule 52
		 'rhs', 2,
sub
#line 407 "etc/nonterminal_parser_grammar.yp"
{
      push(@{$_[1]},[ 'SYMB', $_[2] ]);
      $_[1];
    }
	],
	[#Rule 53
		 'rhs', 3,
sub
#line 412 "etc/nonterminal_parser_grammar.yp"
{
      if (defined $_[2])
      {
        push(@{$_[1]}, [ 'BRACED_CODE', $_[2], $_[3] ] );
      }
      else
      {
        push(@{$_[1]}, [ 'BRACED_CODE', $_[3] ] );
      }
      $_[1];
    }
	],
	[#Rule 54
		 'rhs', 3,
sub
#line 424 "etc/nonterminal_parser_grammar.yp"
{
                       	defined($$precedences{$_[3][0]})
                    or  do {
                        _SyntaxError(1,"No precedence for symbol $_[3][0]",
                                         $_[3][1]);
                        return undef;
                    };

                    ++$$precterm{$_[3][0]};
                    my $temp = $$precedences{$_[3][0]};

                    push(@{$_[1]}, [ 'PERCENT_PREC', $temp ] );
                    $_[1];
    }
	],
	[#Rule 55
		 'symbol', 1, undef
	],
	[#Rule 56
		 'symbol', 1,
sub
#line 443 "etc/nonterminal_parser_grammar.yp"
{
    if (exists $$aliases{$_[1][0]})
    {
      $_[1][0] = $$aliases{$_[1][0]};
    }
    else
    {
      # Must be a literal, in which case we don't touch it.
    }
    $_[1];
  }
	],
	[#Rule 57
		 'action_opt', 0, undef
	],
	[#Rule 58
		 'action_opt', 1, undef
	],
	[#Rule 59
		 'action', 1, undef
	],
	[#Rule 60
		 'string_as_id', 1,
sub
#line 468 "etc/nonterminal_parser_grammar.yp"
{
        if (exists $$aliases{$_[1][0]})
        {
              exists($$syms{$$aliases{$_[1][0]}})
          or  do {
              $$syms{$$aliases{$_[1][0]}} = $_[1][1];
              $$term{$$aliases{$_[1][0]}} = undef;
          };
        }
        else
        {
              exists($$syms{$_[1][0]})
          or  do {
              $$syms{$_[1][0]} = $_[1][1];
              $$term{$_[1][0]} = undef;
          };
        }
        $_[1]
    }
	],
	[#Rule 61
		 'string_content', 1,
sub
#line 492 "etc/nonterminal_parser_grammar.yp"
{
      $_[1][0] =~ s/.(.*)./$1/;
      $_[1]
    }
	],
	[#Rule 62
		 'epilogue_opt', 0, undef
	],
	[#Rule 63
		 'epilogue_opt', 2,
sub
#line 501 "etc/nonterminal_parser_grammar.yp"
{
      $epilogue=$_[2]
    }
	],
	[#Rule 64
		 'ID', 1,
sub
#line 506 "etc/nonterminal_parser_grammar.yp"
{
                        exists($$syms{$_[1][0]})
                    or  do {
                        $$syms{$_[1][0]} = $_[1][1];
                        $$term{$_[1][0]} = undef;
                    };
                    $_[1]
             }
	]
],
                                  @_);
    bless($self,$class);
}

#line 516 "etc/nonterminal_parser_grammar.yp"

sub _Error {
    my($value)=$_[0]->YYCurval;

    my($what)= $token ? "input: '$$value[0]'" : "end of input";

    _SyntaxError(1,"Unexpected $what",$$value[1]);
}

sub _Lexer {
 
    #At EOF
        pos($$input) >= length($$input)
    and return('',[ undef, -1 ]);

    #In Epilogue section
        $lexlevel > 1
    and do {
        my($pos)=pos($$input);

        $lineno[0]=$lineno[1];
        $lineno[1]=-1;
        pos($$input)=length($$input);
        return('EPILOGUE',[ substr($$input,$pos), $lineno[0] ]);
    };

    #Skip blanks
        $$input=~m{\G((?:
                            \s+           # any white space char
                        |   \#[^\n]*\n    # Perl like comments
                        |   /\*.*?\*/     # C like comments
                        |   //[^\n]*\n    # C++ like comments
                        )+)}xsgc
    and do {
        my($blanks)=$1;

        #Maybe At EOF
            pos($$input) >= length($$input)
        and return('',[ undef, -1 ]);

        $lineno[1]+= $blanks=~tr/\n//;
    };

    $lineno[0]=$lineno[1];

        $$input=~/\G<([A-Za-z_.][A-Za-z0-9_.]*)>/gc
    and return('TYPE',[ $1, $lineno[0] ]);

        $$input=~m{\G
                     ([A-Za-z_.][A-Za-z0-9_.]*) #identifier
                     ((?:
                            \s+           # any white space char
                        |   \#[^\n]*\n    # Perl like comments
                        |   /\*.*?\*/     # C like comments
                        |   //[^\n]*\n    # C++ like comments
                        )*)
                     :        # colon
                 }xsgc
    and do {
        my($blanks)=$2;

        $lineno[1]+= $blanks=~tr/\n//;

        return('ID_COLON',[ $1, $lineno[0] ]);
    };

        $$input=~/\G([A-Za-z_.][A-Za-z0-9_.]*)/gc
    and do {
            $1 eq 'error'
        and do {
            return('ERROR',[ 'error', $lineno[0] ]);
        };
        return('IDENT',[ $1, $lineno[0] ]);
    };

        $$input=~/\G('(?:[^'\\]|\\\\|\\'|\\)+?')/gc
    and do {
            $1 eq "'error'"
        and do {
            _SyntaxError(0,"Literal 'error' ".
                           "will be treated as error token",$lineno[0]);
            return('ERROR',[ 'error', $lineno[0] ]);
        };
        return('STRING',[ $1, $lineno[0] ]);
    };

        $$input=~/\G("(?:[^"\\]|\\\\|\\"|\\)+?")/gc
    and do {
            $1 eq '"error"'
        and do {
            _SyntaxError(0,'Literal "error" '.
                           "will be treated as error token",$lineno[0]);
            return('ERROR',[ 'error', $lineno[0] ]);
        };
        return('STRING',[ $1, $lineno[0] ]);
    };

        $$input=~/\G(%%)/gc
    and do {
        ++$lexlevel;
        return($1, [ $1, $lineno[0] ]);
    };

        $$input=~/\G\{/gc
    and do {
        my $code;

        my $level = 1;
        my $from=pos($$input);
        my $to;


        while($$input =~ /\G(.*?
                               (?:
                                   \#[^\n]*\n    # Perl like comments
                                 | \/\*.*?\*\/     # C like comments
                                 | \/\/[^\n]*\n    # C++ like comments
                                 | (?<!\\)'.*?(?<!\\)'  # Single-quoted strings
                                 | (?<!\\)".*?(?<!\\)"  # Double-quoted strings
                                 | ([{}]|$)         # Our match or EOF
                               )
                            )/xsgc)
        {
          if (defined $2)
          {
            if ($2 eq '}')
            {
              $level--;

              unless($level)
              {
                $to = pos($$input) - 1;
                last;
              }
            }
            elsif ($2 eq '{')
            {
              $level++;
            }
            else
            {
              $to = length $$input;
              print(2,"Unmatched { opened line $lineno[0]",-1);
              last;
            }
          }
        }

        $code = substr($$input,$from,$to-$from);

        $lineno[1]+= $code=~tr/\n//;

        # Lookahead to resolve shift/reduce error
        {
          my $old_pos = pos $$input;
          if ($$input =~ /\G\s*\{/)
          {
            pos $$input = $old_pos;
            return('BRACED_CODE_WITH_BRACED_CODE_FOLLOWING',[ $code, $lineno[0] ]);
          }
          else
          {
            pos $$input = $old_pos;
            return('BRACED_CODE',[ $code, $lineno[0] ]);
          }
        }
    };

    if($lexlevel == 0) {# In declarations section
            $$input=~/\G%left/gc
        and return('PERCENT_LEFT',[ 'LEFT', $lineno[0] ]);
            $$input=~/\G%right/gc
        and return('PERCENT_RIGHT',[ 'RIGHT', $lineno[0] ]);
            $$input=~/\G%nonassoc/gc
        and return('PERCENT_NONASSOC',[ 'NONASSOC', $lineno[0] ]);
            $$input=~/\G%(start)/gc
        and return('PERCENT_START',[ undef, $lineno[0] ]);
            $$input=~/\G%(expect)/gc
        and return('PERCENT_EXPECT',[ undef, $lineno[0] ]);
            $$input=~/\G%\{/gc
        and do {
            my($code);

            my $from=pos($$input);
            my $to;

            while($$input =~ m{\G(.*?
                                         (?:
                                             \#[^\n]*\n    # Perl like comments
                                           | /\*.*?\*/     # C like comments
                                           | //[^\n]*\n    # C++ like comments
                                           | (%\}|$)         # Our match or EOF
                                         )
                                     )}xsgc)
            {
              if (defined $2)
              {
                if ($2 eq '%}')
                {
                  $to = pos($$input) - 2;
                }
                else
                {
                  $to = length $$input;
                  _SyntaxError(2,"Unmatched \%{ opened line $lineno[0]",-1)
                }

                last;
              }
            }

            $code = substr($$input,$from,$to-$from);

            $lineno[1]+= $code=~tr/\n//;
            return('PROLOGUE',[ $code, $lineno[0] ]);
        };

            $$input=~/\G%(token)/gc
        and return('PERCENT_TOKEN',[ undef, $lineno[0] ]);
            $$input=~/\G%(type)/gc
        and return('PERCENT_TYPE',[ undef, $lineno[0] ]);
            $$input=~/\G%(union)/gc
        and return('PERCENT_UNION',[ undef, $lineno[0] ]);
            $$input=~/\G%(debug)/gc
        and return('PERCENT_DEBUG',[ undef, $lineno[0] ]);
            $$input=~/\G%(defines)/gc
        and return('PERCENT_DEFINES',[ undef, $lineno[0] ]);
            $$input=~/\G%(file-prefix)/gc
        and return('PERCENT_FILE_PREFIX',[ undef, $lineno[0] ]);
            $$input=~/\G%(locations)/gc
        and return('PERCENT_LOCATIONS',[ undef, $lineno[0] ]);
            $$input=~/\G%(name-prefix)/gc
        and return('PERCENT_NAME_PREFIX',[ undef, $lineno[0] ]);
            $$input=~/\G%(no-lines)/gc
        and return('PERCENT_NO_LINES',[ undef, $lineno[0] ]);
            $$input=~/\G%(output)/gc
        and return('PERCENT_OUTPUT',[ undef, $lineno[0] ]);
            $$input=~/\G%(parse-param)/gc
        and return('PERCENT_PARSE_PARAM',[ undef, $lineno[0] ]);
            $$input=~/\G%(pure[-_]parser)/gc
        and return('PERCENT_PURE_PARSER',[ undef, $lineno[0] ]);
            $$input=~/\G%(token-table)/gc
        and return('PERCENT_TOKEN_TABLE',[ undef, $lineno[0] ]);
            $$input=~/\G%(verbose)/gc
        and return('PERCENT_VERBOSE',[ undef, $lineno[0] ]);
            $$input=~/\G%(yacc)/gc
        and return('PERCENT_YACC',[ undef, $lineno[0] ]);

            $$input=~/\G([0-9]+)/gc
        and return('INT',[ $1, $lineno[0] ]);

    }
    else {# In rule section
            $$input=~/\G%(prec)/gc
        and return('PERCENT_PREC',[ undef, $lineno[0] ]);
    }

        $$input=~/\G=/gc
    and return('EQUAL',[ undef, $lineno[0] ]);
        $$input=~/\G;/gc
    and return('SEMICOLON',[ undef, $lineno[0] ]);
        $$input=~/\G\|/gc
    and return('PIPE',[ undef, $lineno[0] ]);

    #Always return something
        $$input=~/\G(.)/sg
    or  die "Parse::Yapp::Grammar::Parse: Match (.) failed: report as a BUG";

        $1 eq "\n"
    and ++$lineno[1];

    ( $1 ,[ $1, $lineno[0] ]);

}

sub _SyntaxError {
    my($level,$message,$lineno)=@_;

    $message= "*".
              [ 'Warning', 'Error', 'Fatal' ]->[$level].
              "* $message, at ".
              ($lineno < 0 ? "eof" : "line $lineno").
              ".\n";

        $level > 1
    and die $message;

    warn $message;

        $level > 0
    and ++$nberr;

        $nberr == 20 
    and die "*Fatal* Too many errors detected.\n"
}

sub _AddRules {
    my($lhs,$lineno)=@{$_[0]};
    my($rhss)=$_[1];

        ref($$nterm{$lhs})
    and do {
        _SyntaxError(1,"Non-terminal $lhs redefined: ".
                       "Previously declared line $$syms{$lhs}",$lineno);
        return;
    };

        ref($$term{$lhs})
    and do {
        my($where) = exists($$token{$lhs}) ? $$token{$lhs} : $$syms{$lhs};
        _SyntaxError(1,"Non-terminal $lhs previously ".
                       "declared as token line $where",$lineno);
        return;
    };

        ref($$nterm{$lhs})      #declared through %type
    or  do {
            $$syms{$lhs}=$lineno;   #Say it's declared here
            delete($$term{$lhs});   #No more a terminal
    };
    $$nterm{$lhs}=[];       #It's a non-terminal now

    my($epsrules)=0;        #To issue a warning if more than one epsilon rule

    for my $rhs (@$rhss) {
        my($tmprule)=[ $lhs, [ ], splice(@$rhs,-2) ]; #Init rule

            @$rhs
        or  do {
            ++$$nullable{$lhs};
            ++$epsrules;
        };

        for (0..$#$rhs) {
            my($what,$value)=@{$$rhs[$_]};

                $what eq 'CODE'
            and do {
                my($name)='@'.++$labelno."-$_";
                push(@$rules,[ $name, [], undef, $value ]);
                push(@{$$tmprule[1]},$name);
                next;
            };
            push(@{$$tmprule[1]},$$value[0]);
        }
        push(@$rules,$tmprule);
        push(@{$$nterm{$lhs}},$#$rules);
    }

        $epsrules > 1
    and _SyntaxError(0,"More than one empty rule for symbol $lhs",$lineno);
}

sub Parse {
    my($self)=shift;

        @_ > 0
    or  croak("No input grammar\n");

    my($parsed)={};

    $input=\$_[0];

    $lexlevel=0;
    @lineno=(1,1);
    $nberr=0;
    $prec=0;
    $labelno=0;

    $declarations=();
    $epilogue="";

    $syms={};
    $token={};
    $term={};
    $precedences={};
    $nterm={};
    $rules=[ undef ];   #reserve slot 0 for start rule
    $precterm={};

    $start="";
    $nullable={};
    $aliases={};
    $expect=0;

    pos($$input)=0;


    $self->YYParse(yylex => \&_Lexer, yyerror => \&_Error);

        $nberr
    and _SyntaxError(2,"Errors detected: No output",-1);

    @$parsed{ 'HEAD', 'TAIL', 'RULES', 'NTERM', 'TERM',
              'NULL', 'PREC', 'SYMS',  'START', 'EXPECT' }
    =       (  $declarations,  $epilogue,  $rules,  $nterm,  $term,
               $nullable, $precterm, $syms, $start, $expect);

    undef($input);
    undef($lexlevel);
    undef(@lineno);
    undef($nberr);
    undef($prec);
    undef($labelno);

    undef($declarations);
    undef($epilogue);

    undef($syms);
    undef($token);
    undef($term);
    undef($precedences);
    undef($nterm);
    undef($rules);
    undef($precterm);

    undef($start);
    undef($nullable);
    undef($aliases);
    undef($expect);

    $parsed
}


1;
