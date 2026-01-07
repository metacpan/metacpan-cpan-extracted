####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package XDR::Parse v1.0.1;
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
			"const" => 2,
			"enum" => 6,
			"union" => 8,
			"typedef" => 10,
			'PREPROC' => 9,
			"struct" => 4,
			'PASSTHROUGH' => 3
		},
		GOTOS => {
			'definitions' => 11,
			'specification' => 7,
			'typeDef' => 12,
			'constantDef' => 5,
			'definition' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'PASSTHROUGH' => 3,
			"struct" => 4,
			'PREPROC' => 9,
			"typedef" => 10,
			"union" => 8,
			"enum" => 6,
			"const" => 2
		},
		DEFAULT => -3,
		GOTOS => {
			'definitions' => 13,
			'constantDef' => 5,
			'typeDef' => 12,
			'definition' => 1
		}
	},
	{#State 2
		ACTIONS => {
			'IDENT' => 14
		}
	},
	{#State 3
		DEFAULT => -5
	},
	{#State 4
		ACTIONS => {
			'IDENT' => 15
		}
	},
	{#State 5
		DEFAULT => -8
	},
	{#State 6
		ACTIONS => {
			'IDENT' => 16
		}
	},
	{#State 7
		ACTIONS => {
			'' => 17
		}
	},
	{#State 8
		ACTIONS => {
			'IDENT' => 18
		}
	},
	{#State 9
		DEFAULT => -6
	},
	{#State 10
		ACTIONS => {
			"void" => 24,
			"double" => 25,
			"struct" => 26,
			"bool" => 27,
			"int" => 20,
			'IDENT' => 19,
			"char" => 21,
			"float" => 22,
			"string" => 23,
			"long" => 33,
			"union" => 35,
			"unsigned" => 36,
			"hyper" => 37,
			"opaque" => 28,
			"enum" => 30,
			"quadruple" => 31,
			"short" => 32
		},
		GOTOS => {
			'declaration' => 29,
			'typeSpecifier' => 34
		}
	},
	{#State 11
		ACTIONS => {
			'TRAILING_COMMENT' => 38
		},
		DEFAULT => -1
	},
	{#State 12
		DEFAULT => -7
	},
	{#State 13
		DEFAULT => -4
	},
	{#State 14
		ACTIONS => {
			"=" => 39
		}
	},
	{#State 15
		ACTIONS => {
			"{" => 41
		},
		GOTOS => {
			'structBody' => 40
		}
	},
	{#State 16
		ACTIONS => {
			"{" => 42
		},
		GOTOS => {
			'enumBody' => 43
		}
	},
	{#State 17
		DEFAULT => 0
	},
	{#State 18
		ACTIONS => {
			"switch" => 44
		},
		GOTOS => {
			'switch' => 45
		}
	},
	{#State 19
		DEFAULT => -48
	},
	{#State 20
		DEFAULT => -30
	},
	{#State 21
		DEFAULT => -33
	},
	{#State 22
		DEFAULT => -41
	},
	{#State 23
		ACTIONS => {
			'IDENT' => 46
		}
	},
	{#State 24
		DEFAULT => -61
	},
	{#State 25
		DEFAULT => -42
	},
	{#State 26
		ACTIONS => {
			"{" => 41
		},
		GOTOS => {
			'structBody' => 47
		}
	},
	{#State 27
		DEFAULT => -44
	},
	{#State 28
		ACTIONS => {
			'IDENT' => 48
		}
	},
	{#State 29
		ACTIONS => {
			";" => 49
		}
	},
	{#State 30
		ACTIONS => {
			"{" => 42
		},
		GOTOS => {
			'enumBody' => 50
		}
	},
	{#State 31
		DEFAULT => -43
	},
	{#State 32
		DEFAULT => -35
	},
	{#State 33
		DEFAULT => -37
	},
	{#State 34
		ACTIONS => {
			"*" => 51,
			'IDENT' => 52
		}
	},
	{#State 35
		ACTIONS => {
			"switch" => 44
		},
		GOTOS => {
			'switch' => 53
		}
	},
	{#State 36
		ACTIONS => {
			"long" => 55,
			"hyper" => 56,
			"int" => 58,
			"char" => 57,
			"short" => 54
		},
		DEFAULT => -31
	},
	{#State 37
		DEFAULT => -39
	},
	{#State 38
		DEFAULT => -2
	},
	{#State 39
		ACTIONS => {
			'CONST' => 59,
			'IDENT' => 60
		}
	},
	{#State 40
		ACTIONS => {
			";" => 61
		}
	},
	{#State 41
		ACTIONS => {
			"enum" => 30,
			"short" => 32,
			"quadruple" => 31,
			"opaque" => 28,
			"unsigned" => 36,
			"hyper" => 37,
			"union" => 35,
			"long" => 33,
			"float" => 22,
			"string" => 23,
			"int" => 20,
			'IDENT' => 19,
			"char" => 21,
			"struct" => 26,
			"bool" => 27,
			"void" => 24,
			"double" => 25
		},
		GOTOS => {
			'declaration' => 63,
			'structItem' => 62,
			'structItems' => 64,
			'typeSpecifier' => 34
		}
	},
	{#State 42
		ACTIONS => {
			'IDENT' => 66
		},
		GOTOS => {
			'enumItems' => 67,
			'enumItem' => 65
		}
	},
	{#State 43
		ACTIONS => {
			";" => 68
		}
	},
	{#State 44
		ACTIONS => {
			"(" => 69
		}
	},
	{#State 45
		ACTIONS => {
			";" => 70
		}
	},
	{#State 46
		ACTIONS => {
			"<" => 71
		}
	},
	{#State 47
		DEFAULT => -46
	},
	{#State 48
		ACTIONS => {
			"[" => 72,
			"<" => 73
		}
	},
	{#State 49
		DEFAULT => -9
	},
	{#State 50
		DEFAULT => -45
	},
	{#State 51
		ACTIONS => {
			'IDENT' => 74
		}
	},
	{#State 52
		ACTIONS => {
			"<" => 75,
			"[" => 76
		},
		DEFAULT => -51
	},
	{#State 53
		DEFAULT => -47
	},
	{#State 54
		DEFAULT => -36
	},
	{#State 55
		DEFAULT => -38
	},
	{#State 56
		DEFAULT => -40
	},
	{#State 57
		DEFAULT => -34
	},
	{#State 58
		DEFAULT => -32
	},
	{#State 59
		ACTIONS => {
			";" => 77
		}
	},
	{#State 60
		ACTIONS => {
			";" => 78
		}
	},
	{#State 61
		DEFAULT => -11
	},
	{#State 62
		ACTIONS => {
			"enum" => 30,
			"short" => 32,
			"quadruple" => 31,
			"opaque" => 28,
			"unsigned" => 36,
			"hyper" => 37,
			"union" => 35,
			"long" => 33,
			"string" => 23,
			"float" => 22,
			"int" => 20,
			'IDENT' => 19,
			"char" => 21,
			"struct" => 26,
			"bool" => 27,
			"void" => 24,
			"double" => 25
		},
		DEFAULT => -23,
		GOTOS => {
			'structItem' => 62,
			'declaration' => 63,
			'typeSpecifier' => 34,
			'structItems' => 79
		}
	},
	{#State 63
		ACTIONS => {
			";" => 80
		}
	},
	{#State 64
		ACTIONS => {
			"}" => 81
		}
	},
	{#State 65
		ACTIONS => {
			"," => 82
		},
		DEFAULT => -27
	},
	{#State 66
		ACTIONS => {
			"=" => 83
		}
	},
	{#State 67
		ACTIONS => {
			"}" => 84
		}
	},
	{#State 68
		DEFAULT => -10
	},
	{#State 69
		ACTIONS => {
			"union" => 35,
			"long" => 33,
			"hyper" => 37,
			"unsigned" => 36,
			"opaque" => 28,
			"short" => 32,
			"quadruple" => 31,
			"enum" => 30,
			"double" => 25,
			"void" => 24,
			"bool" => 27,
			"struct" => 26,
			"char" => 21,
			'IDENT' => 19,
			"int" => 20,
			"float" => 22,
			"string" => 23
		},
		GOTOS => {
			'typeSpecifier' => 34,
			'declaration' => 85
		}
	},
	{#State 70
		DEFAULT => -12
	},
	{#State 71
		ACTIONS => {
			">" => 86,
			'IDENT' => 89,
			'CONST' => 87
		},
		GOTOS => {
			'value' => 88
		}
	},
	{#State 72
		ACTIONS => {
			'CONST' => 87,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 90
		}
	},
	{#State 73
		ACTIONS => {
			'CONST' => 87,
			">" => 91,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 92
		}
	},
	{#State 74
		DEFAULT => -60
	},
	{#State 75
		ACTIONS => {
			'CONST' => 87,
			">" => 93,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 94
		}
	},
	{#State 76
		ACTIONS => {
			'CONST' => 87,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 95
		}
	},
	{#State 77
		DEFAULT => -13
	},
	{#State 78
		DEFAULT => -14
	},
	{#State 79
		DEFAULT => -24
	},
	{#State 80
		DEFAULT => -25
	},
	{#State 81
		DEFAULT => -22
	},
	{#State 82
		ACTIONS => {
			'IDENT' => 66
		},
		GOTOS => {
			'enumItems' => 96,
			'enumItem' => 65
		}
	},
	{#State 83
		ACTIONS => {
			'CONST' => 87,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 97
		}
	},
	{#State 84
		DEFAULT => -26
	},
	{#State 85
		ACTIONS => {
			")" => 98
		}
	},
	{#State 86
		DEFAULT => -58
	},
	{#State 87
		DEFAULT => -49
	},
	{#State 88
		ACTIONS => {
			">" => 99
		}
	},
	{#State 89
		DEFAULT => -50
	},
	{#State 90
		ACTIONS => {
			"]" => 100
		}
	},
	{#State 91
		DEFAULT => -56
	},
	{#State 92
		ACTIONS => {
			">" => 101
		}
	},
	{#State 93
		DEFAULT => -53
	},
	{#State 94
		ACTIONS => {
			">" => 102
		}
	},
	{#State 95
		ACTIONS => {
			"]" => 103
		}
	},
	{#State 96
		DEFAULT => -28
	},
	{#State 97
		DEFAULT => -29
	},
	{#State 98
		ACTIONS => {
			"{" => 104
		}
	},
	{#State 99
		DEFAULT => -59
	},
	{#State 100
		DEFAULT => -55
	},
	{#State 101
		DEFAULT => -57
	},
	{#State 102
		DEFAULT => -54
	},
	{#State 103
		DEFAULT => -52
	},
	{#State 104
		ACTIONS => {
			"case" => 105
		},
		GOTOS => {
			'caseClauses' => 106,
			'caseClause' => 107,
			'caseBody' => 108
		}
	},
	{#State 105
		ACTIONS => {
			'CONST' => 87,
			'IDENT' => 89
		},
		GOTOS => {
			'value' => 109
		}
	},
	{#State 106
		ACTIONS => {
			"default" => 110
		},
		DEFAULT => -16,
		GOTOS => {
			'defaultClause' => 111
		}
	},
	{#State 107
		ACTIONS => {
			"case" => 105
		},
		DEFAULT => -18,
		GOTOS => {
			'caseClauses' => 112,
			'caseClause' => 107
		}
	},
	{#State 108
		ACTIONS => {
			"}" => 113
		}
	},
	{#State 109
		ACTIONS => {
			":" => 114
		}
	},
	{#State 110
		ACTIONS => {
			":" => 115
		}
	},
	{#State 111
		DEFAULT => -17
	},
	{#State 112
		DEFAULT => -19
	},
	{#State 113
		DEFAULT => -15
	},
	{#State 114
		ACTIONS => {
			"long" => 33,
			"union" => 35,
			"unsigned" => 36,
			"hyper" => 37,
			"opaque" => 28,
			"enum" => 30,
			"quadruple" => 31,
			"short" => 32,
			"void" => 24,
			"double" => 25,
			"struct" => 26,
			"bool" => 27,
			"int" => 20,
			'IDENT' => 19,
			"char" => 21,
			"string" => 23,
			"float" => 22
		},
		GOTOS => {
			'typeSpecifier' => 34,
			'declaration' => 116
		}
	},
	{#State 115
		ACTIONS => {
			'IDENT' => 19,
			"int" => 20,
			"char" => 21,
			"string" => 23,
			"float" => 22,
			"void" => 24,
			"double" => 25,
			"struct" => 26,
			"bool" => 27,
			"opaque" => 28,
			"enum" => 30,
			"short" => 32,
			"quadruple" => 31,
			"union" => 35,
			"long" => 33,
			"unsigned" => 36,
			"hyper" => 37
		},
		GOTOS => {
			'typeSpecifier' => 34,
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
                        name => delete $_[3]->{name},
                        declaration => $_[3],
                        comments => $_[2]->{comments},
                        trailing_comments => $_[4]->{comments}
                     },
                     members => {
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
#line 108 "xdr.yp"
{ +{ clauses => $_[1] } }
	],
	[#Rule 17
		 'caseBody', 2,
sub
#line 109 "xdr.yp"
{ +{ clauses => $_[1], default => $_[2] } }
	],
	[#Rule 18
		 'caseClauses', 1,
sub
#line 113 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 19
		 'caseClauses', 2,
sub
#line 114 "xdr.yp"
{ unshift @{ $_[2] }, $_[1]; $_[2] }
	],
	[#Rule 20
		 'caseClause', 5,
sub
#line 118 "xdr.yp"
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
#line 129 "xdr.yp"
{
            # What to do with comments on the ':'?
            +{ name => delete $_[3]->{name},
               declaration => $_[3],
               comments => $_[1]->{comments},
               location => $_[1]->{location},
               trailing_comments => $_[4]->{comments} } }
	],
	[#Rule 22
		 'structBody', 3,
sub
#line 139 "xdr.yp"
{ +{ members => $_[2],
                                     comments => $_[1]->{comments},
                                     location => $_[1]->{location},
                                     trailing_comments => $_[3]->{comments} } }
	],
	[#Rule 23
		 'structItems', 1,
sub
#line 146 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 24
		 'structItems', 2,
sub
#line 147 "xdr.yp"
{ unshift @{ $_[2] }, $_[1]; $_[2] }
	],
	[#Rule 25
		 'structItem', 2,
sub
#line 151 "xdr.yp"
{
            +{ name => delete $_[1]->{name},
               declaration => $_[1],
               trailing_comments => $_[2]->{comments} } }
	],
	[#Rule 26
		 'enumBody', 3,
sub
#line 158 "xdr.yp"
{ +{ elements => $_[2],
                                     comments => $_[1]->{comments},
                                     location => $_[1]->{location},
                                     trailing_comments => $_[3]->{comments} } }
	],
	[#Rule 27
		 'enumItems', 1,
sub
#line 165 "xdr.yp"
{ [ $_[1] ] }
	],
	[#Rule 28
		 'enumItems', 3,
sub
#line 166 "xdr.yp"
{ $_[1]->{trailing_comments} = $_[2]->{comments};
                                  unshift @{ $_[3] }, $_[1]; $_[3] }
	],
	[#Rule 29
		 'enumItem', 3,
sub
#line 171 "xdr.yp"
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
#line 181 "xdr.yp"
{ +{ spec => 'primitive', name => 'int', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 31
		 'typeSpecifier', 1,
sub
#line 182 "xdr.yp"
{ +{ spec => 'primitive', name => 'int', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 32
		 'typeSpecifier', 2,
sub
#line 183 "xdr.yp"
{ +{ spec => 'primitive', name => 'int', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 33
		 'typeSpecifier', 1,
sub
#line 184 "xdr.yp"
{ +{ spec => 'primitive', name => 'char', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 34
		 'typeSpecifier', 2,
sub
#line 185 "xdr.yp"
{ +{ spec => 'primitive', name => 'char', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 35
		 'typeSpecifier', 1,
sub
#line 186 "xdr.yp"
{ +{ spec => 'primitive', name => 'short', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 36
		 'typeSpecifier', 2,
sub
#line 187 "xdr.yp"
{ +{ spec => 'primitive', name => 'short', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 37
		 'typeSpecifier', 1,
sub
#line 188 "xdr.yp"
{ +{ spec => 'primitive', name => 'long', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 38
		 'typeSpecifier', 2,
sub
#line 189 "xdr.yp"
{ +{ spec => 'primitive', name => 'long', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 39
		 'typeSpecifier', 1,
sub
#line 190 "xdr.yp"
{ +{ spec => 'primitive', name => 'hyper', unsigned => 0, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 40
		 'typeSpecifier', 2,
sub
#line 191 "xdr.yp"
{ +{ spec => 'primitive', name => 'hyper', unsigned => 1, comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 41
		 'typeSpecifier', 1,
sub
#line 192 "xdr.yp"
{ +{ spec => 'primitive', name => 'float', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 42
		 'typeSpecifier', 1,
sub
#line 193 "xdr.yp"
{ +{ spec => 'primitive', name => 'double', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 43
		 'typeSpecifier', 1,
sub
#line 194 "xdr.yp"
{ +{ spec => 'primitive', name => 'quadruple', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 44
		 'typeSpecifier', 1,
sub
#line 195 "xdr.yp"
{ +{ spec => 'primitive', name => 'bool', comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 45
		 'typeSpecifier', 2,
sub
#line 196 "xdr.yp"
{ +{ spec => 'enum', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 46
		 'typeSpecifier', 2,
sub
#line 197 "xdr.yp"
{ +{ spec => 'struct', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 47
		 'typeSpecifier', 2,
sub
#line 198 "xdr.yp"
{ +{ spec => 'union', declaration => $_[2], comments => $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 48
		 'typeSpecifier', 1,
sub
#line 199 "xdr.yp"
{ +{ spec => 'named', name => $_[1], comments => delete $_[1]->{comments}, location => $_[1]->{location} } }
	],
	[#Rule 49
		 'value', 1, undef
	],
	[#Rule 50
		 'value', 1, undef
	],
	[#Rule 51
		 'declaration', 2,
sub
#line 208 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 52
		 'declaration', 5,
sub
#line 213 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               count => $_[4],
               variable => 0,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 53
		 'declaration', 4,
sub
#line 221 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 54
		 'declaration', 5,
sub
#line 229 "xdr.yp"
{
            +{ name => $_[2],
               type => $_[1],
               array => 1,
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 55
		 'declaration', 5,
sub
#line 237 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               count => $_[4],
               variable => 0,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 56
		 'declaration', 4,
sub
#line 244 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 57
		 'declaration', 5,
sub
#line 251 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 58
		 'declaration', 4,
sub
#line 258 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => undef,
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 59
		 'declaration', 5,
sub
#line 265 "xdr.yp"
{
            +{ name => $_[2],
               type => { spec => 'primitive', name => $_[1] },
               max  => $_[4],
               variable => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 60
		 'declaration', 3,
sub
#line 272 "xdr.yp"
{
            +{ name => $_[3],
               type => $_[1],
               pointer => 1,
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	],
	[#Rule 61
		 'declaration', 1,
sub
#line 278 "xdr.yp"
{
            +{ type => { spec => 'primitive', name => $_[1] },
               comments => delete $_[1]->{comments},
               location => $_[1]->{location} } }
	]
],
                                  @_);
    bless($self,$class);
}

#line 285 "xdr.yp"



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
    elsif ($yydata->{INPUT} =~ s/^(-?\d+|0x[0-9a-f]+)(?=\b|$)//i) {
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

XDR::Parse - Creation of an AST of an XDR specification (RFC4506)

=head1 SYNOPSIS

  use XDR::Parse;
  use Data::Dumper;

  my $p = XDR::Parse->new;
  print Dumper( $p->parse( \*STDIN ) );

=head1 VERSION

1.0.1

=head1 DESCRIPTION

This module contains a parser for the XDR (eXternal Data Representation)
language as defined in RFC4506.  The result is an abstract syntax tree
(AST) which can be used for further processing.

This module extends the supported integer types with C<char>, C<short> and
C<long>, all of which seem to be supported by C<rpcgen>, the tool consuming
XDR to generate remote applications.

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

  const my_const = 0x123;     # hexadecimal
  const my_other_const = 123; # decimal
  const my_third_const = 012; # octal

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

Th C<declaration> node of C<struct> definitions has a single key (C<members>):
an array of nodes with C<name> and C<declaration> keys describing the members
of the struct type. For more details on the C<type> node, see below.

=head4 'union' declarations

The C<declaration> node of C<union> definitions has a single key (C<switch>):
itself a node which contains a C<members> and a C<discriminator> key.  The
discriminator node has a C<name> and a C<type> key; the C<members> node
contains one or two keys: C<cases> and optionally C<default>.  C<cases> is an
array of nodes defining the members of the union; each element consists of
three keys: C<value>, C<name> and <declaration>. C<value> is the value
associated with the discriminator, to indicate the current definition.
C<name> is the name of the member. C<declaration> contains the type declaration
for the member.

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
members follow the same pattern as documented in the respective sections on
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
