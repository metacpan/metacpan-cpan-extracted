#########################################################################
#
#      This file was generated using Parse::Yapp version 0.16.
#
#          Don't edit this file, use source file instead.
#
#               ANY CHANGE MADE HERE WILL BE LOST !
#
#########################################################################
package XML::XQL::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '0.16',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildQName' => 19,
			'WildNCName' => 18,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 6,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 26,
			'Query' => 27,
			'Intersection' => 15,
			'Bang' => 30,
			'Sequence' => 31,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 1
		ACTIONS => {
			"[" => 36
		},
		DEFAULT => -51,
		GOTOS => {
			'Subscript_2' => 37
		}
	},
	{#State 2
		DEFAULT => -43
	},
	{#State 3
		ACTIONS => {
			'MATCH' => 40,
			'COMPARE' => 39
		},
		GOTOS => {
			'ComparisonOp' => 38
		}
	},
	{#State 4
		DEFAULT => -65
	},
	{#State 5
		ACTIONS => {
			"or" => 41
		},
		DEFAULT => -21
	},
	{#State 6
		ACTIONS => {
			'SeqOp' => 42
		},
		DEFAULT => -19
	},
	{#State 7
		DEFAULT => -67
	},
	{#State 8
		DEFAULT => -59
	},
	{#State 9
		DEFAULT => -42
	},
	{#State 10
		ACTIONS => {
			'COMPARE' => -37,
			'MATCH' => -37
		},
		DEFAULT => -33
	},
	{#State 11
		ACTIONS => {
			"*" => 29,
			'NCName' => 25
		},
		GOTOS => {
			'WildQName' => 43,
			'WildNCName' => 18
		}
	},
	{#State 12
		DEFAULT => -62
	},
	{#State 13
		DEFAULT => -68
	},
	{#State 14
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 2,
			'LValue' => 44,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 45,
			'Subscript' => 35
		}
	},
	{#State 15
		ACTIONS => {
			'UnionOp' => 46
		},
		DEFAULT => -27
	},
	{#State 16
		ACTIONS => {
			".." => -17,
			'XQLName_Paren' => -17,
			"\@" => -17,
			'NCName' => -17,
			"(" => -17,
			"*" => -17,
			"." => -17
		},
		DEFAULT => -44
	},
	{#State 17
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 47,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 18
		ACTIONS => {
			":" => 48
		},
		DEFAULT => -4
	},
	{#State 19
		DEFAULT => -10
	},
	{#State 20
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 2,
			'LValue' => 49,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 45,
			'Subscript' => 35
		}
	},
	{#State 21
		DEFAULT => -25
	},
	{#State 22
		ACTIONS => {
			'NCName' => 25,
			'TEXT' => 50,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			")" => 54,
			"*" => 29,
			'NUMBER' => 51,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			'INTEGER' => 53,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 52,
			'Invocation_2' => 55,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'Param' => 56,
			'RelativeTerm' => 12,
			'Negation' => 26,
			'AttributeName' => 13,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 23
		DEFAULT => -18
	},
	{#State 24
		ACTIONS => {
			"*" => 29,
			'NCName' => 25,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"(" => 28,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 57,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'Subscript' => 35
		}
	},
	{#State 25
		DEFAULT => -2
	},
	{#State 26
		ACTIONS => {
			"and" => 58
		},
		DEFAULT => -23
	},
	{#State 27
		ACTIONS => {
			'' => 59
		}
	},
	{#State 28
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 6,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 26,
			'Query' => 60,
			'Intersection' => 15,
			'Bang' => 30,
			'Sequence' => 31,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 29
		DEFAULT => -3
	},
	{#State 30
		ACTIONS => {
			"//" => 23,
			"/" => 61
		},
		DEFAULT => -46,
		GOTOS => {
			'PathOp' => 62
		}
	},
	{#State 31
		DEFAULT => -1
	},
	{#State 32
		DEFAULT => -66
	},
	{#State 33
		ACTIONS => {
			"intersect" => 63
		},
		DEFAULT => -29
	},
	{#State 34
		DEFAULT => -64
	},
	{#State 35
		ACTIONS => {
			"!" => 64
		},
		DEFAULT => -48
	},
	{#State 36
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			'INTEGER' => 65,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'Subquery' => 67,
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 6,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Range' => 68,
			'Path' => 10,
			'IndexArg' => 69,
			'RelativeTerm' => 12,
			'IndexList' => 66,
			'AttributeName' => 13,
			'Negation' => 26,
			'Query' => 70,
			'Intersection' => 15,
			'Bang' => 30,
			'Sequence' => 31,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 37
		DEFAULT => -50
	},
	{#State 38
		ACTIONS => {
			'NCName' => 25,
			'TEXT' => 71,
			"(" => 28,
			"*" => 29,
			'NUMBER' => 72,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			'INTEGER' => 74,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 2,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 73,
			'Subscript' => 35,
			'RValue' => 75
		}
	},
	{#State 39
		DEFAULT => -31
	},
	{#State 40
		DEFAULT => -32
	},
	{#State 41
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 76,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 26,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 42
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 6,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 26,
			'Intersection' => 15,
			'Bang' => 30,
			'Sequence' => 77,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 43
		DEFAULT => -11
	},
	{#State 44
		ACTIONS => {
			'MATCH' => 40,
			'COMPARE' => 39
		},
		GOTOS => {
			'ComparisonOp' => 78
		}
	},
	{#State 45
		DEFAULT => -37
	},
	{#State 46
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 79,
			'RelativePath' => 2,
			'LValue' => 3,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 47
		DEFAULT => -26
	},
	{#State 48
		ACTIONS => {
			"*" => 29,
			'NCName' => 25
		},
		GOTOS => {
			'WildNCName' => 80
		}
	},
	{#State 49
		ACTIONS => {
			'MATCH' => 40,
			'COMPARE' => 39
		},
		GOTOS => {
			'ComparisonOp' => 81
		}
	},
	{#State 50
		DEFAULT => -9
	},
	{#State 51
		DEFAULT => -8
	},
	{#State 52
		DEFAULT => -6
	},
	{#State 53
		DEFAULT => -7
	},
	{#State 54
		DEFAULT => -13
	},
	{#State 55
		DEFAULT => -12
	},
	{#State 56
		ACTIONS => {
			"," => 83
		},
		DEFAULT => -15,
		GOTOS => {
			'Invocation_3' => 82
		}
	},
	{#State 57
		DEFAULT => -45
	},
	{#State 58
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 84,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Negation' => 26,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 59
		DEFAULT => -0
	},
	{#State 60
		ACTIONS => {
			")" => 85
		}
	},
	{#State 61
		DEFAULT => -17
	},
	{#State 62
		ACTIONS => {
			"*" => 29,
			'NCName' => 25,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"(" => 28,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 86,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'Subscript' => 35
		}
	},
	{#State 63
		ACTIONS => {
			'NCName' => 25,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'RelativePath' => 2,
			'LValue' => 3,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Intersection' => 87,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 64
		ACTIONS => {
			'XQLName_Paren' => 22
		},
		GOTOS => {
			'Invocation' => 88
		}
	},
	{#State 65
		ACTIONS => {
			"to" => 89
		},
		DEFAULT => -56
	},
	{#State 66
		ACTIONS => {
			"]" => 90
		}
	},
	{#State 67
		ACTIONS => {
			"]" => 91
		}
	},
	{#State 68
		DEFAULT => -57
	},
	{#State 69
		ACTIONS => {
			"," => 93
		},
		DEFAULT => -54,
		GOTOS => {
			'IndexList_2' => 92
		}
	},
	{#State 70
		DEFAULT => -61
	},
	{#State 71
		DEFAULT => -41
	},
	{#State 72
		DEFAULT => -40
	},
	{#State 73
		DEFAULT => -38
	},
	{#State 74
		DEFAULT => -39
	},
	{#State 75
		DEFAULT => -34
	},
	{#State 76
		DEFAULT => -22
	},
	{#State 77
		DEFAULT => -20
	},
	{#State 78
		ACTIONS => {
			'NCName' => 25,
			'TEXT' => 71,
			"(" => 28,
			"*" => 29,
			'NUMBER' => 72,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			'INTEGER' => 74,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 2,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 73,
			'Subscript' => 35,
			'RValue' => 94
		}
	},
	{#State 79
		DEFAULT => -28
	},
	{#State 80
		DEFAULT => -5
	},
	{#State 81
		ACTIONS => {
			'NCName' => 25,
			'TEXT' => 71,
			"(" => 28,
			"*" => 29,
			'NUMBER' => 72,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			'INTEGER' => 74,
			"\@" => 11
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'RelativeTerm' => 12,
			'AttributeName' => 13,
			'Filter' => 1,
			'Bang' => 30,
			'RelativePath' => 2,
			'Invocation' => 32,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 73,
			'Subscript' => 35,
			'RValue' => 95
		}
	},
	{#State 82
		ACTIONS => {
			")" => 96
		}
	},
	{#State 83
		ACTIONS => {
			'NCName' => 25,
			'TEXT' => 50,
			"(" => 28,
			"any" => 14,
			"all" => 20,
			"*" => 29,
			'NUMBER' => 51,
			".." => 4,
			'XQLName_Paren' => 22,
			"." => 34,
			"//" => 23,
			"/" => 16,
			"\@" => 11,
			'INTEGER' => 53,
			"not" => 17
		},
		GOTOS => {
			'WildNCName' => 18,
			'WildQName' => 19,
			'Filter' => 1,
			'Union' => 21,
			'RelativePath' => 2,
			'LValue' => 3,
			'Conjunction' => 5,
			'Disjunction' => 52,
			'ElementName' => 7,
			'Grouping' => 8,
			'PathOp' => 24,
			'AbsolutePath' => 9,
			'Path' => 10,
			'Param' => 97,
			'RelativeTerm' => 12,
			'Negation' => 26,
			'AttributeName' => 13,
			'Intersection' => 15,
			'Bang' => 30,
			'Invocation' => 32,
			'Comparison' => 33,
			'Subscript' => 35
		}
	},
	{#State 84
		DEFAULT => -24
	},
	{#State 85
		DEFAULT => -63
	},
	{#State 86
		DEFAULT => -47
	},
	{#State 87
		DEFAULT => -30
	},
	{#State 88
		DEFAULT => -49
	},
	{#State 89
		ACTIONS => {
			'INTEGER' => 98
		}
	},
	{#State 90
		DEFAULT => -52
	},
	{#State 91
		DEFAULT => -60
	},
	{#State 92
		DEFAULT => -53
	},
	{#State 93
		ACTIONS => {
			'INTEGER' => 65
		},
		GOTOS => {
			'IndexArg' => 99,
			'Range' => 68
		}
	},
	{#State 94
		DEFAULT => -35
	},
	{#State 95
		DEFAULT => -36
	},
	{#State 96
		DEFAULT => -14
	},
	{#State 97
		ACTIONS => {
			"," => 83
		},
		DEFAULT => -15,
		GOTOS => {
			'Invocation_3' => 100
		}
	},
	{#State 98
		DEFAULT => -58
	},
	{#State 99
		ACTIONS => {
			"," => 93
		},
		DEFAULT => -54,
		GOTOS => {
			'IndexList_2' => 101
		}
	},
	{#State 100
		DEFAULT => -16
	},
	{#State 101
		DEFAULT => -55
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'Query', 1, undef
	],
	[#Rule 2
		 'WildNCName', 1, undef
	],
	[#Rule 3
		 'WildNCName', 1, undef
	],
	[#Rule 4
		 'WildQName', 1,
sub {
 [ Name => $_[1] ]; 
}
	],
	[#Rule 5
		 'WildQName', 3,
sub {
 
			[ NameSpace => $_[1], Name => $_[2]]; 
}
	],
	[#Rule 6
		 'Param', 1, undef
	],
	[#Rule 7
		 'Param', 1,
sub {
 new XML::XQL::Number ($_[1]); 
}
	],
	[#Rule 8
		 'Param', 1,
sub {
 new XML::XQL::Number ($_[1]); 
}
	],
	[#Rule 9
		 'Param', 1,
sub {
 new XML::XQL::Text ($_[1]); 
}
	],
	[#Rule 10
		 'ElementName', 1,
sub {
 new XML::XQL::Element (@{$_[1]}); 
}
	],
	[#Rule 11
		 'AttributeName', 2,
sub {
 new XML::XQL::Attribute (@{$_[2]}); 
}
	],
	[#Rule 12
		 'Invocation', 2,
sub {

			my ($func, $type) = $_[0]->{Query}->findFunctionOrMethod ($_[1], $_[2]);

			new XML::XQL::Invocation (Name => $_[1], 
						  Args => $_[2],
						  Func => $func,
						  Type => $type); 
}
	],
	[#Rule 13
		 'Invocation_2', 1,
sub {
 [] 
}
	],
	[#Rule 14
		 'Invocation_2', 3,
sub {
 unshift @{$_[2]}, $_[1]; $_[2]; 
}
	],
	[#Rule 15
		 'Invocation_3', 0,
sub {
 [] 
}
	],
	[#Rule 16
		 'Invocation_3', 3,
sub {
 unshift @{$_[3]}, $_[2]; $_[3]; 
}
	],
	[#Rule 17
		 'PathOp', 1, undef
	],
	[#Rule 18
		 'PathOp', 1, undef
	],
	[#Rule 19
		 'Sequence', 1, undef
	],
	[#Rule 20
		 'Sequence', 3,
sub {

		    new XML::XQL::Sequence (Left => $_[1], Oper => $_[2], 
					    Right => $_[3]); 
}
	],
	[#Rule 21
		 'Disjunction', 1, undef
	],
	[#Rule 22
		 'Disjunction', 3,
sub {
 
		    new XML::XQL::Or (Left => $_[1], Right => $_[3]); 
}
	],
	[#Rule 23
		 'Conjunction', 1, undef
	],
	[#Rule 24
		 'Conjunction', 3,
sub {
 
		    new XML::XQL::And (Left => $_[1], Right => $_[3]); 
}
	],
	[#Rule 25
		 'Negation', 1, undef
	],
	[#Rule 26
		 'Negation', 2,
sub {
 new XML::XQL::Not (Left => $_[2]); 
}
	],
	[#Rule 27
		 'Union', 1, undef
	],
	[#Rule 28
		 'Union', 3,
sub {
 
		    new XML::XQL::Union (Left => $_[1], Right => $_[3]); 
}
	],
	[#Rule 29
		 'Intersection', 1, undef
	],
	[#Rule 30
		 'Intersection', 3,
sub {
 
		    new XML::XQL::Intersect ($_[1], $_[3]); 
}
	],
	[#Rule 31
		 'ComparisonOp', 1,
sub {

		  [ $_[1], $_[0]->{Query}->findComparisonOperator ($_[1]) ]; 
}
	],
	[#Rule 32
		 'ComparisonOp', 1,
sub {

		  [ $_[1], $_[0]->{Query}->findComparisonOperator ($_[1]) ]; 
}
	],
	[#Rule 33
		 'Comparison', 1, undef
	],
	[#Rule 34
		 'Comparison', 3,
sub {

			new XML::XQL::Compare (All => 0, Left => $_[1], 
				Oper => $_[2]->[0], Func => $_[2]->[1], 
				Right => $_[3]); 
}
	],
	[#Rule 35
		 'Comparison', 4,
sub {

			new XML::XQL::Compare (All => 0, Left => $_[2], 
				Oper => $_[3]->[0], Func => $_[3]->[0],
				Right => $_[4]); 
}
	],
	[#Rule 36
		 'Comparison', 4,
sub {

			new XML::XQL::Compare (All => 1, Left => $_[2], 
				Oper => $_[3]->[0], Func => $_[3]->[0],
				Right => $_[4]); 
}
	],
	[#Rule 37
		 'LValue', 1, undef
	],
	[#Rule 38
		 'RValue', 1, undef
	],
	[#Rule 39
		 'RValue', 1,
sub {
 new XML::XQL::Number ($_[1]); 
}
	],
	[#Rule 40
		 'RValue', 1,
sub {
 new XML::XQL::Number ($_[1]); 
}
	],
	[#Rule 41
		 'RValue', 1,
sub {
 new XML::XQL::Text ($_[1]); 
}
	],
	[#Rule 42
		 'Path', 1, undef
	],
	[#Rule 43
		 'Path', 1, undef
	],
	[#Rule 44
		 'AbsolutePath', 1,
sub {
 new XML::Root; 
}
	],
	[#Rule 45
		 'AbsolutePath', 2,
sub {
 
		    new XML::XQL::Path (PathOp => $_[1], Right => $_[2]); 
}
	],
	[#Rule 46
		 'RelativePath', 1, undef
	],
	[#Rule 47
		 'RelativePath', 3,
sub {
 
		    new XML::XQL::Path (Left => $_[1], PathOp => $_[2], 
				        Right => $_[3]); 
}
	],
	[#Rule 48
		 'Bang', 1, undef
	],
	[#Rule 49
		 'Bang', 3,
sub {

		    XML::XQL::parseError ("only methods (not functions) can be used after the Bang (near '!" . $_[3]->{Name} . "'")
			unless $_[3]->isMethod;

		    new XML::XQL::Bang (Left => $_[1], 
				        Right => $_[3]); 
}
	],
	[#Rule 50
		 'Subscript', 2,
sub {
 
		    defined($_[2]) ? 
			new XML::XQL::Subscript (Left => $_[1], 
					    IndexList => $_[2]) : $_[1]; 
}
	],
	[#Rule 51
		 'Subscript_2', 0, undef
	],
	[#Rule 52
		 'Subscript_2', 3,
sub {
 $_[2]; 
}
	],
	[#Rule 53
		 'IndexList', 2,
sub {
 push (@{$_[1]}, @{$_[2]}); $_[1]; 
}
	],
	[#Rule 54
		 'IndexList_2', 0,
sub {
 [] 
}
	],
	[#Rule 55
		 'IndexList_2', 3,
sub {
 push (@{$_[2]}, @{$_[3]}); $_[2]; 
}
	],
	[#Rule 56
		 'IndexArg', 1,
sub {
 [ $_[1], $_[1] ]; 
}
	],
	[#Rule 57
		 'IndexArg', 1, undef
	],
	[#Rule 58
		 'Range', 3,
sub {

		    # Syntactic Constraint 9:
		    # If both integers are positive or if both integers are 
		    # negative, the first integer must be less than or
          	    # equal to the second integer. 

		    XML::XQL::parseError (
			"$_[1] should be less than $_[3] in '$_[1] $_[2] $_[3]'")
				if ($_[1] > $_[3] && ($_[1] < 0) == ($_[3] < 0));
		    [ $_[1], $_[3] ]; 
}
	],
	[#Rule 59
		 'Filter', 1, undef
	],
	[#Rule 60
		 'Filter', 4,
sub {
 
			new XML::XQL::Filter (Left => $_[1], Right => $_[3]); 
}
	],
	[#Rule 61
		 'Subquery', 1, undef
	],
	[#Rule 62
		 'Grouping', 1, undef
	],
	[#Rule 63
		 'Grouping', 3,
sub {
 $_[2]; 
}
	],
	[#Rule 64
		 'RelativeTerm', 1,
sub {
 new XML::XQL::Current; 
}
	],
	[#Rule 65
		 'RelativeTerm', 1,
sub {
 new XML::XQL::Parent; 
}
	],
	[#Rule 66
		 'RelativeTerm', 1, undef
	],
	[#Rule 67
		 'RelativeTerm', 1, undef
	],
	[#Rule 68
		 'RelativeTerm', 1, undef
	]
],
                                  @_);
    bless($self,$class);
}



1;
