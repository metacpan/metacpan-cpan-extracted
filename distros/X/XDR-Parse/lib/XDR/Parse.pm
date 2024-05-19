####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package XDR::Parse v0.2.0;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 5 "xdr.yp"




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"enum" => 8,
			"struct" => 9,
			"union" => 5,
			'PASSTHROUGH' => 1,
			'PREPROC' => 11,
			"typedef" => 3,
			"const" => 10
		},
		GOTOS => {
			'definitions' => 6,
			'constantDef' => 2,
			'definition' => 7,
			'typeDef' => 12,
			'specification' => 4
		}
	},
	{#State 1
		DEFAULT => -5
	},
	{#State 2
		DEFAULT => -8
	},
	{#State 3
		ACTIONS => {
			"long" => 28,
			"quadruple" => 29,
			"int" => 31,
			"float" => 30,
			"union" => 27,
			"char" => 24,
			"double" => 23,
			'IDENT' => 26,
			"unsigned" => 21,
			"opaque" => 22,
			"string" => 20,
			"struct" => 17,
			"void" => 19,
			"hyper" => 16,
			"bool" => 15,
			"short" => 13,
			"enum" => 14
		},
		GOTOS => {
			'declaration' => 25,
			'typeSpecifier' => 18
		}
	},
	{#State 4
		ACTIONS => {
			'' => 32
		}
	},
	{#State 5
		ACTIONS => {
			'IDENT' => 33
		}
	},
	{#State 6
		ACTIONS => {
			'TRAILING_COMMENT' => 34
		},
		DEFAULT => -1
	},
	{#State 7
		ACTIONS => {
			"const" => 10,
			'PREPROC' => 11,
			"union" => 5,
			"struct" => 9,
			"typedef" => 3,
			'PASSTHROUGH' => 1,
			"enum" => 8
		},
		DEFAULT => -3,
		GOTOS => {
			'typeDef' => 12,
			'definition' => 7,
			'definitions' => 35,
			'constantDef' => 2
		}
	},
	{#State 8
		ACTIONS => {
			'IDENT' => 36
		}
	},
	{#State 9
		ACTIONS => {
			'IDENT' => 37
		}
	},
	{#State 10
		ACTIONS => {
			'IDENT' => 38
		}
	},
	{#State 11
		DEFAULT => -6
	},
	{#State 12
		DEFAULT => -7
	},
	{#State 13
		DEFAULT => -34
	},
	{#State 14
		ACTIONS => {
			"{" => 39
		},
		GOTOS => {
			'enumBody' => 40
		}
	},
	{#State 15
		DEFAULT => -43
	},
	{#State 16
		DEFAULT => -38
	},
	{#State 17
		ACTIONS => {
			"{" => 41
		},
		GOTOS => {
			'structBody' => 42
		}
	},
	{#State 18
		ACTIONS => {
			'IDENT' => 43,
			"*" => 44
		}
	},
	{#State 19
		DEFAULT => -60
	},
	{#State 20
		ACTIONS => {
			'IDENT' => 45
		}
	},
	{#State 21
		ACTIONS => {
			"int" => 49,
			"long" => 48,
			"hyper" => 46,
			"char" => 50,
			"short" => 47
		}
	},
	{#State 22
		ACTIONS => {
			'IDENT' => 51
		}
	},
	{#State 23
		DEFAULT => -41
	},
	{#State 24
		DEFAULT => -32
	},
	{#State 25
		ACTIONS => {
			";" => 52
		}
	},
	{#State 26
		DEFAULT => -47
	},
	{#State 27
		ACTIONS => {
			"switch" => 53
		},
		GOTOS => {
			'switch' => 54
		}
	},
	{#State 28
		DEFAULT => -36
	},
	{#State 29
		DEFAULT => -42
	},
	{#State 30
		DEFAULT => -40
	},
	{#State 31
		DEFAULT => -30
	},
	{#State 32
		DEFAULT => 0
	},
	{#State 33
		ACTIONS => {
			"switch" => 53
		},
		GOTOS => {
			'switch' => 55
		}
	},
	{#State 34
		DEFAULT => -2
	},
	{#State 35
		DEFAULT => -4
	},
	{#State 36
		ACTIONS => {
			"{" => 39
		},
		GOTOS => {
			'enumBody' => 56
		}
	},
	{#State 37
		ACTIONS => {
			"{" => 41
		},
		GOTOS => {
			'structBody' => 57
		}
	},
	{#State 38
		ACTIONS => {
			"=" => 58
		}
	},
	{#State 39
		ACTIONS => {
			'IDENT' => 60
		},
		GOTOS => {
			'enumItems' => 61,
			'enumItem' => 59
		}
	},
	{#State 40
		DEFAULT => -44
	},
	{#State 41
		ACTIONS => {
			"enum" => 14,
			"short" => 13,
			"bool" => 15,
			"hyper" => 16,
			"struct" => 17,
			"void" => 19,
			"string" => 20,
			"unsigned" => 21,
			"opaque" => 22,
			"double" => 23,
			"char" => 24,
			'IDENT' => 26,
			"union" => 27,
			"long" => 28,
			"int" => 31,
			"quadruple" => 29,
			"float" => 30
		},
		GOTOS => {
			'structItem' => 63,
			'typeSpecifier' => 18,
			'structItems' => 64,
			'declaration' => 62
		}
	},
	{#State 42
		DEFAULT => -45
	},
	{#State 43
		ACTIONS => {
			"<" => 65,
			"[" => 66
		},
		DEFAULT => -50
	},
	{#State 44
		ACTIONS => {
			'IDENT' => 67
		}
	},
	{#State 45
		ACTIONS => {
			"<" => 68
		}
	},
	{#State 46
		DEFAULT => -39
	},
	{#State 47
		DEFAULT => -35
	},
	{#State 48
		DEFAULT => -37
	},
	{#State 49
		DEFAULT => -31
	},
	{#State 50
		DEFAULT => -33
	},
	{#State 51
		ACTIONS => {
			"[" => 70,
			"<" => 69
		}
	},
	{#State 52
		DEFAULT => -9
	},
	{#State 53
		ACTIONS => {
			"(" => 71
		}
	},
	{#State 54
		DEFAULT => -46
	},
	{#State 55
		ACTIONS => {
			";" => 72
		}
	},
	{#State 56
		ACTIONS => {
			";" => 73
		}
	},
	{#State 57
		ACTIONS => {
			";" => 74
		}
	},
	{#State 58
		ACTIONS => {
			'IDENT' => 75,
			'CONST' => 76
		}
	},
	{#State 59
		ACTIONS => {
			"," => 77
		},
		DEFAULT => -27
	},
	{#State 60
		ACTIONS => {
			"=" => 78
		}
	},
	{#State 61
		ACTIONS => {
			"}" => 79
		}
	},
	{#State 62
		ACTIONS => {
			";" => 80
		}
	},
	{#State 63
		ACTIONS => {
			"void" => 19,
			"struct" => 17,
			"string" => 20,
			"short" => 13,
			"enum" => 14,
			"hyper" => 16,
			"bool" => 15,
			"union" => 27,
			"float" => 30,
			"quadruple" => 29,
			"int" => 31,
			"long" => 28,
			"opaque" => 22,
			"unsigned" => 21,
			'IDENT' => 26,
			"double" => 23,
			"char" => 24
		},
		DEFAULT => -23,
		GOTOS => {
			'typeSpecifier' => 18,
			'structItem' => 63,
			'structItems' => 81,
			'declaration' => 62
		}
	},
	{#State 64
		ACTIONS => {
			"}" => 82
		}
	},
	{#State 65
		ACTIONS => {
			'CONST' => 86,
			">" => 85,
			'IDENT' => 84
		},
		GOTOS => {
			'value' => 83
		}
	},
	{#State 66
		ACTIONS => {
			'IDENT' => 84,
			'CONST' => 86
		},
		GOTOS => {
			'value' => 87
		}
	},
	{#State 67
		DEFAULT => -59
	},
	{#State 68
		ACTIONS => {
			'IDENT' => 84,
			'CONST' => 86,
			">" => 89
		},
		GOTOS => {
			'value' => 88
		}
	},
	{#State 69
		ACTIONS => {
			'IDENT' => 84,
			">" => 91,
			'CONST' => 86
		},
		GOTOS => {
			'value' => 90
		}
	},
	{#State 70
		ACTIONS => {
			'IDENT' => 84,
			'CONST' => 86
		},
		GOTOS => {
			'value' => 92
		}
	},
	{#State 71
		ACTIONS => {
			"unsigned" => 21,
			"opaque" => 22,
			"char" => 24,
			"double" => 23,
			'IDENT' => 26,
			"union" => 27,
			"long" => 28,
			"float" => 30,
			"quadruple" => 29,
			"int" => 31,
			"short" => 13,
			"enum" => 14,
			"hyper" => 16,
			"bool" => 15,
			"struct" => 17,
			"void" => 19,
			"string" => 20
		},
		GOTOS => {
			'declaration' => 93,
			'typeSpecifier' => 18
		}
	},
	{#State 72
		DEFAULT => -12
	},
	{#State 73
		DEFAULT => -10
	},
	{#State 74
		DEFAULT => -11
	},
	{#State 75
		ACTIONS => {
			";" => 94
		}
	},
	{#State 76
		ACTIONS => {
			";" => 95
		}
	},
	{#State 77
		ACTIONS => {
			'IDENT' => 60
		},
		GOTOS => {
			'enumItems' => 96,
			'enumItem' => 59
		}
	},
	{#State 78
		ACTIONS => {
			'IDENT' => 84,
			'CONST' => 86
		},
		GOTOS => {
			'value' => 97
		}
	},
	{#State 79
		DEFAULT => -26
	},
	{#State 80
		DEFAULT => -25
	},
	{#State 81
		DEFAULT => -24
	},
	{#State 82
		DEFAULT => -22
	},
	{#State 83
		ACTIONS => {
			">" => 98
		}
	},
	{#State 84
		DEFAULT => -49
	},
	{#State 85
		DEFAULT => -52
	},
	{#State 86
		DEFAULT => -48
	},
	{#State 87
		ACTIONS => {
			"]" => 99
		}
	},
	{#State 88
		ACTIONS => {
			">" => 100
		}
	},
	{#State 89
		DEFAULT => -57
	},
	{#State 90
		ACTIONS => {
			">" => 101
		}
	},
	{#State 91
		DEFAULT => -55
	},
	{#State 92
		ACTIONS => {
			"]" => 102
		}
	},
	{#State 93
		ACTIONS => {
			")" => 103
		}
	},
	{#State 94
		DEFAULT => -14
	},
	{#State 95
		DEFAULT => -13
	},
	{#State 96
		DEFAULT => -28
	},
	{#State 97
		DEFAULT => -29
	},
	{#State 98
		DEFAULT => -53
	},
	{#State 99
		DEFAULT => -51
	},
	{#State 100
		DEFAULT => -58
	},
	{#State 101
		DEFAULT => -56
	},
	{#State 102
		DEFAULT => -54
	},
	{#State 103
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 104
		ACTIONS => {
			"case" => 105
		},
		GOTOS => {
			'caseClauses' => 107,
			'caseBody' => 106,
			'caseClause' => 108
		}
	},
	{#State 105
		ACTIONS => {
			'CONST' => 86,
			'IDENT' => 84
		},
		GOTOS => {
			'value' => 109
		}
	},
	{#State 106
		ACTIONS => {
			"}" => 110
		}
	},
	{#State 107
		ACTIONS => {
			"default" => 111
		},
		DEFAULT => -16,
		GOTOS => {
			'defaultClause' => 112
		}
	},
	{#State 108
		ACTIONS => {
			"case" => 105
		},
		DEFAULT => -18,
		GOTOS => {
			'caseClause' => 108,
			'caseClauses' => 113
		}
	},
	{#State 109
		ACTIONS => {
			":" => 114
		}
	},
	{#State 110
		DEFAULT => -15
	},
	{#State 111
		ACTIONS => {
			":" => 115
		}
	},
	{#State 112
		DEFAULT => -17
	},
	{#State 113
		DEFAULT => -19
	},
	{#State 114
		ACTIONS => {
			"long" => 28,
			"float" => 30,
			"int" => 31,
			"quadruple" => 29,
			"union" => 27,
			"double" => 23,
			"char" => 24,
			'IDENT' => 26,
			"unsigned" => 21,
			"opaque" => 22,
			"string" => 20,
			"struct" => 17,
			"void" => 19,
			"bool" => 15,
			"hyper" => 16,
			"enum" => 14,
			"short" => 13
		},
		GOTOS => {
			'declaration' => 116,
			'typeSpecifier' => 18
		}
	},
	{#State 115
		ACTIONS => {
			"struct" => 17,
			"void" => 19,
			"string" => 20,
			"short" => 13,
			"enum" => 14,
			"bool" => 15,
			"hyper" => 16,
			"union" => 27,
			"long" => 28,
			"float" => 30,
			"quadruple" => 29,
			"int" => 31,
			"unsigned" => 21,
			"opaque" => 22,
			"double" => 23,
			"char" => 24,
			'IDENT' => 26
		},
		GOTOS => {
			'typeSpecifier' => 18,
			'declaration' => 117
		}
	},
	{#State 116
		ACTIONS => {
			";" => 118
		}
	},
	{#State 117
		ACTIONS => {
			";" => 119
		}
	},
	{#State 118
		DEFAULT => -20
	},
	{#State 119
		DEFAULT => -21
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specification', 1, undef
	],
	[#Rule 2
		 'specification', 2,
sub
#line 14 "xdr.yp"
{ [ @{ $_[1] }, $_[2] ] }
	],
	[#Rule 3
		 'definitions', 1,
sub
#line 18 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 4
		 'definitions', 2,
sub
#line 19 "xdr.yp"
{ unshift @{$_[2]}, $_[1]; $_[2] }
	],
	[#Rule 5
		 'definition', 1,
sub
#line 23 "xdr.yp"
{ +{ def => 'passthrough', value => $_[1] } }
	],
	[#Rule 6
		 'definition', 1,
sub
#line 24 "xdr.yp"
{ +{ def => 'preprocessor', value => $_[1] } }
	],
	[#Rule 7
		 'definition', 1, undef
	],
	[#Rule 8
		 'definition', 1, undef
	],
	[#Rule 9
		 'typeDef', 3,
sub
#line 30 "xdr.yp"
{
                  +{ def => 'typedef',
                     name => delete $_[2]->{name},
                     definition => $_[2],
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[3]->{comments} } }
	],
	[#Rule 10
		 'typeDef', 4,
sub
#line 37 "xdr.yp"
{
                  +{ def => 'enum',
                     name => $_[2],
                     definition => {
                         type => { spec => 'enum', declaration => $_[3] }
                     },
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[4]->{comments} } }
	],
	[#Rule 11
		 'typeDef', 4,
sub
#line 46 "xdr.yp"
{
                  +{ def => 'struct',
                     name => $_[2],
                     definition => {
                         type => { spec => 'struct', declaration => $_[3] }
                     },
                     comments => delete $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[4]->{comments} } }
	],
	[#Rule 12
		 'typeDef', 4,
sub
#line 55 "xdr.yp"
{
                  +{ def => 'union',
                     name => $_[2],
                     definition => {
                         type => { spec => 'union', declaration => $_[3] }
                     },
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[4]->{comments} } }
	],
	[#Rule 13
		 'constantDef', 5,
sub
#line 67 "xdr.yp"
{
                  # What to do with comments before the '=' sign?
                  +{ def => 'const',
                     name => $_[2],
                     value => $_[4],
                     type => 'numeric',
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[5]->{comments} } }
	],
	[#Rule 14
		 'constantDef', 5,
sub
#line 76 "xdr.yp"
{
                  # What to do with comments before the '=' sign?
                  +{ def => 'const',
                     name => $_[2],
                     value => $_[4],
                     type => 'symbolic',
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[5]->{comments} } }
	],
	[#Rule 15
		 'switch', 7,
sub
#line 88 "xdr.yp"
{
                  +{ discriminator => {
                        declaration => $_[3],
                        comments => $_[2]->{comments},
                        trailing_comments => $_[4]->{comments}
                     },
                     handlers => {
                        cases => $_[6]->{clauses},
                        default => $_[6]->{default},
                        comments => $_[5]->{comments},
                        location => $_[5]->{location},
                        trailing_comments => $_[7]->{comments}
                     },
                     comments => $_[1]->{comments},
                     location => $_[1]->{location},
                     trailing_comments => $_[7]->{comments} } }
	],
	[#Rule 16
		 'caseBody', 1,
sub
#line 107 "xdr.yp"
{ +{ clauses => $_[1] } }
	],
	[#Rule 17
		 'caseBody', 2,
sub
#line 108 "xdr.yp"
{ +{ clauses => $_[1], default => $_[2] } }
	],
	[#Rule 18
		 'caseClauses', 1,
sub
#line 112 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 19
		 'caseClauses', 2,
sub
#line 113 "xdr.yp"
{ unshift @{ $_[2] }, $_[1]; $_[2] }
	],
	[#Rule 20
		 'caseClause', 5,
sub
#line 117 "xdr.yp"
{
            $_[2]->{trailing_comments} = $_[3]->{comments};
            +{ value => $_[2],
               name => delete $_[4]->{name},
               declaration => $_[4],
               comments => $_[1]->{comments},
               location => $_[1]->{location},
               trailing_comments => $_[5]->{comments} } }
	],
	[#Rule 21
		 'defaultClause', 4,
sub
#line 128 "xdr.yp"
{
            # What to do with comments on the ':'?
            +{ declaration => $_[3],
               comments => $_[1]->{comments},
               location => $_[1]->{location},
               trailing_comments => $_[4]->{comments} } }
	],
	[#Rule 22
		 'structBody', 3,
sub
#line 137 "xdr.yp"
{ +{ fields => $_[2],
                                     comments => $_[1]->{comments},
                                     location => $_[1]->{location},
                                     trailing_comments => $_[3]->{comments} } }
	],
	[#Rule 23
		 'structItems', 1,
sub
#line 144 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 24
		 'structItems', 2,
sub
#line 145 "xdr.yp"
{ unshift @{ $_[2] }, $_[1]; $_[2] }
	],
	[#Rule 25
		 'structItem', 2,
sub
#line 149 "xdr.yp"
{
            +{ %{ $_[1] },
               trailing_comments => $_[2]->{comments} } }
	],
	[#Rule 26
		 'enumBody', 3,
sub
#line 155 "xdr.yp"
{ +{ elements => $_[2],
                                     comments => $_[1]->{comments},
                                     location => $_[1]->{location},
                                     trailing_comments => $_[3]->{comments} } }
	],
	[#Rule 27
		 'enumItems', 1,
sub
#line 162 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 28
		 'enumItems', 3,
sub
#line 163 "xdr.yp"
{ $_[1]->{trailing_comments} = $_[2]->{comments};
                                  unshift @{ $_[3] }, $_[1]; $_[3] }
	],
	[#Rule 29
		 'enumItem', 3,
sub
#line 168 "xdr.yp"
{
        # What to do with comments on the '=' sign?
        $_[1]->{trailing_comments} = $_[2]->{comments};
        +{ name => $_[1],
           value => $_[3],
           comments => delete $_[1]->{comments},
           location => $_[1]->{location} } }
	],
	[#Rule 30
		 'typeSpecifier', 1,
sub
#line 178 "xdr.yp"
{ +{ spec => 'primitive', name => 'int', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 31
		 'typeSpecifier', 2,
sub
#line 179 "xdr.yp"
{ +{ spec => 'primitive', name => 'int', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 32
		 'typeSpecifier', 1,
sub
#line 180 "xdr.yp"
{ +{ spec => 'primitive', name => 'char', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 33
		 'typeSpecifier', 2,
sub
#line 181 "xdr.yp"
{ +{ spec => 'primitive', name => 'char', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 34
		 'typeSpecifier', 1,
sub
#line 182 "xdr.yp"
{ +{ spec => 'primitive', name => 'short', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 35
		 'typeSpecifier', 2,
sub
#line 183 "xdr.yp"
{ +{ spec => 'primitive', name => 'short', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 36
		 'typeSpecifier', 1,
sub
#line 184 "xdr.yp"
{ +{ spec => 'primitive', name => 'long', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 37
		 'typeSpecifier', 2,
sub
#line 185 "xdr.yp"
{ +{ spec => 'primitive', name => 'long', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 38
		 'typeSpecifier', 1,
sub
#line 186 "xdr.yp"
{ +{ spec => 'primitive', name => 'hyper', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 39
		 'typeSpecifier', 2,
sub
#line 187 "xdr.yp"
{ +{ spec => 'primitive', name => 'hyper', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 40
		 'typeSpecifier', 1,
sub
#line 188 "xdr.yp"
{ +{ spec => 'primitive', name => 'float', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 41
		 'typeSpecifier', 1,
sub
#line 189 "xdr.yp"
{ +{ spec => 'primitive', name => 'double', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 42
		 'typeSpecifier', 1,
sub
#line 190 "xdr.yp"
{ +{ spec => 'primitive', name => 'quadruple', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 43
		 'typeSpecifier', 1,
sub
#line 191 "xdr.yp"
{ +{ spec => 'primitive', name => 'bool', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 44
		 'typeSpecifier', 2,
sub
#line 192 "xdr.yp"
{ +{ spec => 'enum', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 45
		 'typeSpecifier', 2,
sub
#line 193 "xdr.yp"
{ +{ spec => 'struct', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 46
		 'typeSpecifier', 2,
sub
#line 194 "xdr.yp"
{ +{ spec => 'union', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 47
		 'typeSpecifier', 1,
sub
#line 195 "xdr.yp"
{ +{ spec => 'named', name => $_[1], comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 48
		 'value', 1, undef
	],
	[#Rule 49
		 'value', 1, undef
	],
	[#Rule 50
		 'declaration', 2,
sub
#line 204 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 51
		 'declaration', 5,
sub
#line 209 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               count => $_[4],
               variable => 0,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 52
		 'declaration', 4,
sub
#line 217 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 53
		 'declaration', 5,
sub
#line 225 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 54
		 'declaration', 5,
sub
#line 233 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               count => $_[4],
               variable => 0,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 55
		 'declaration', 4,
sub
#line 240 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 56
		 'declaration', 5,
sub
#line 247 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 57
		 'declaration', 4,
sub
#line 254 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 58
		 'declaration', 5,
sub
#line 261 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 59
		 'declaration', 3,
sub
#line 268 "xdr.yp"
{
            +{ name => $_[3],
               type => $_[1],
               pointer => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 60
		 'declaration', 1,
sub
#line 274 "xdr.yp"
{
            +{ type => { spec => 'primitive', name => $_[1] },
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	]
],
                                  @_);
    bless($self,$class);
}

#line 281 "xdr.yp"



sub _Lexer {
  my ($fh, $parser) = @_;
  my $yydata = $parser->YYData;
  my @comments;
  my $comment;
  my $comment_start;

  $yydata->{LINENO} //= 0;
  while (1) {
    unless ($yydata->{INPUT}) {
       $yydata->{INPUT} = <$fh>;
       $yydata->{LINENO}++;
       $yydata->{COLNO} = 1;

       if (@comments and not $yydata->{INPUT}) {
           return ('TRAILING_COMMENT', {
               content => '',
               comments => \@comments,
               location => $comment_start
           });
       }

       return ('', undef) unless $yydata->{INPUT};

       if ($yydata->{INPUT} =~ s/^(%.*)//) {
           return ('PASSTHROUGH', {
               content => $1,
               comments => \@comments,
               location => [ $yydata->{LINENO}, 1 ]
           });
       }
       if ($yydata->{INPUT} =~ s/^(#.*)//) {
           return ('PREPROC', {
               content => $1,
               comments => \@comments,
               location => [ $yydata->{LINENO}, 1 ]
           });
       }
    }

    $yydata->{INPUT} =~ s/^\s+//;
    $yydata->{COLNO} += length($&);
    next unless $yydata->{INPUT};

    my $token_start = [ $yydata->{LINENO}, $yydata->{COLNO} ];
    if ($yydata->{INPUT} =~ s|^/\*||) { # strip comments
       $yydata->{COLNO} += length($&);
       $comment = '';
       while (1) {
          if ($yydata->{INPUT} =~ s|(.*?)\*/||) {
            $yydata->{COLNO} += length($&);
            push @comments, { content => $comment . $1, location => $token_start };
            last;
          }
          $comment .= $yydata->{INPUT};
          $yydata->{INPUT} = <$fh>;
          $yydata->{LINENO}++;
          $yydata->{COLNO} = 1;
          die "Unclosed comment" unless $yydata->{INPUT};
       }
    }
    elsif ($yydata->{INPUT} =~ s/^(const|typedef|enum|union|struct|switch|case|default|unsigned|int|char|short|long|hyper|float|string|double|quadruple|bool|opaque|void)\b(?!_)//) {
      $yydata->{COLNO} += length($&);
      return ($1, {
          content => $1,
          comments => \@comments,
          location => $token_start
      });
    }
    elsif ($yydata->{INPUT} =~ s/^([a-z][a-z0-9_]*)//i) {
      $yydata->{COLNO} += length($&);
      return ('IDENT', {
          content => $1,
          comments => \@comments,
          location => $token_start
      });
    }
    elsif ($yydata->{INPUT} =~ s/^(-?\d+|0x\d+)(?=\b|$)//) {
      $yydata->{COLNO} += length($&);
      return ('CONST', {
          content => $1,
          comments => \@comments,
          location => $token_start
      });
    }
    elsif ($yydata->{INPUT} =~ s/^(.)//) {
     $yydata->{COLNO} += length($&);
     return ($1, {
          content => $1,
          comments => \@comments,
          location => $token_start
      });
    }
    else {
      die "Remaining input: '$yydata->{INPUT}'";
    }
  }
}

sub _Error {
   my $tok = $_[0]->YYCurtok;
   my $val = $_[0]->YYCurval;
   my $line = $tok ? "line: $val->{location}->[0]" : 'at <EOF>';

   print STDERR "Parse error at '$val->{content}' (line: $line)\n";
}

sub parse {
  my ($self, $fh) = @_;

  $self->YYParse( yylex   => sub { _Lexer( $fh, @_ ); },
                  yyerror => \&_Error );
}

=head1 NAME

XDR::Parse - Creation of an AST of an XDR specification

=head1 SYNOPSIS

  use XDR::Parse;
  use Data::Dumper;

  my $p = XDR::Parse->new;
  print Dumper( $p->parse( \*STDIN ) );

=head1 VERSION

0.2.0

=head1 DESCRIPTION

This module contains a parser for the XDR (eXternal Data Representation)
language.  The result is an abstract syntax tree (AST) which can be used
for further processing.

=head2 AST

At the top level, the AST is an array of nodes which can be one of the
following, distinguished by the C<def> key in the node's hash:

=over 8

=item * a 'pass through' instruction (C<passthrough>)

This type of nodes contains a line which starts with '%'; the instruction
to C<rpcgen> to copy that line to output verbatim

=item * a preprocessor instruction (C<preprocessor>)

This type of nodes contains a line which starts with '#'; C<rpcgen> typically
invokes C<cpp> to preprocess its input -- this module simply takes input and
parses that; input which hasn't been preprocessed may contain this type of node

=item * constant declarations (C<const>)

=item * type declarations

Type definitions come in four subtypes C<enum>, C<subst>, C<typedef>
and C<union>

=item * trailing comment

Comments in the input are linked to the first syntax node following the comment;
files having comments between the last syntax and the end of the file, will
contain a special C<trailing comment> node, which doesn't model syntax, but is
required to prevent loosing the last comments in the file.

=back

Each node in the tree -not just the toplevel - is a hash which may have any or
all of the following keys:

=over 8

=item * comments

Is an array containing all comments following the previous syntax node and
preceeding the one to which the comment(s) are attached

=item * location

Is an array of two elements: the line and column number of the beginning of the
syntax captured by that node

=item * trailing_comments

Trailing comments happen when a node encloses a scope with a termination which
itself is not included in the AST representation.  E.g. the closing ';' in a
C<typedef>:

   typedef string our_string<> /* trailing comment */ ;

=back

=head3 Constant declarations

Constant declarations exist in two types, distinguished by the C<type> key in
the node's hash:

=over 8

=item * C<numeric>

  const my_const = 0x123;
  const my_other_const = 123;

=item * C<symbolic>

  const the_const = my_other_const;

=back

=head3 Type declarations

Top level nodes with a C<def> key valued C<typedef>, C<enum>, C<struct> or
C<union> define types of the named language construct. These nodes share the
following keys, in addition to the keys shared by all nodes:

=over 8

=item * name

Name of the type being defined.

=item * definition

The node making up the definition of the type, holding a C<type> node with
two keys, C<spec> and C<declaration>. The value of the C<spec> key is one of
C<enum>, C<struct> or C<union>. The elements are specified by the content of
the C<declaration> key.

=back

=head4 'typedef' declarations

This node is a 'declaration' node as documented in the section
'declaration' nodes below.

=head4 'enum' declarations

The C<declaration> node of C<enum> definitions has a single key (C<elements>):
an array of nodes with C<name> and C<value> keys, one for each value defined
in the enum type.

=head4 'struct' declarations

Th C<declaration> node of C<struct> definitions has a single key (C<fields>):
an array of nodes with C<name> and C<type> keys describing the fields of the
struct type. For more details on the C<type> node, see below.

=head4 'union' declarations

The C<declaration> node of C<union> definitions has a single key (C<switch>):
itself a node which contains a C<handlers> and a C<discriminator> key.  The
discriminator node has a C<name> and a C<type> key; the C<handlers> node
contains one or two keys: C<cases> and optionally C<default>.  C<cases> is an
array of nodes defining the fields of the union; each element consists of
three keys: C<value>, C<name> and <declaration>. C<value> is the value
associated with the discriminator, to indicate the current definition.
C<name> is the name of the field. C<declaration> contains the type declaration
for the field.

=head4 'declaration' nodes

These nodes contain a C<type> key specifying the basic type of the declaration
as documented below under L</'type' nodes in declarations>,
with a number of modifiers:

=over 8

=item * pointer

Optional. Mutually exclusive with the C<array> indicator.

=item * array

Optional. Mutually exclusive with the C<pointer> indicator.

When the C<array> boolean is true, the following additional keys may exist:

=over 8

=item * variable

Indicates whether the array is of variable length.

=item * max

Indicates the maximum number of items in the array. May be C<undef>, if no
maximum was specified.

Note: this value may be specified using symbolic constant.

=item * count

Indicates the exact number of items in the array, when C<variable> is false
or absent.

Note: this value may be specified using symbolic constant.

=back

=back

=head4 'type' nodes in declarations

These nodes either define an inline C<enum>, C<struct> or C<union>, or refer to any
of the types defined in the standard or at the toplevel, as indiceted by the C<spec>
key using these values:

=over 8

=item * primitive

The value in the C<name> key refers to a built-in type. When the named type is one
of the integer type (C<char>, C<short>, C<int>, C<long> or C<hyper>), the type hash
contains the additional key C<unsigned>.

The primitive types C<string> and C<opaque> support the same additional keys as
arrays (C<count>, C<max> and C<variable>).  These apply to the data within them
and do not mean to define arrays of strings/"opaques".

=item * named

The value in the C<name> key refers to a defined type.

=item * enum

Defines an inline enum through the type's C<declaration> key.

=item * struct

Defines an inline struct through the type's C<declaration> key.

=item * union

Defines an inline union through the type's C<declaration> key.

=back

The node in the C<declaration> key of the inline C<enum>, C<struct> and C<union>
fields follow the same pattern as documented in the respective sections on
declarations above.

=head1 METHODS

=head2 new

  my $parser = XDR::Parse->new;

=head2 parse

  my $ast = $parser->parse( \*STDIN );

=head2 YYParse (inherited)

=head1 LICENSE

This distribution may be used under the same terms as Perl itself.

=head1 AUTHOR

=over 8

=item * Erik Huelsmann

=back

=head1 SEE ALSO

L<XDR>, L<perlrpcgen>

=cut
1;
