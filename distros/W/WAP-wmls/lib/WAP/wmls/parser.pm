####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package WAP::wmls::parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'USE' => 6,
			'FUNCTION' => 7,
			'EXTERN' => 9
		},
		GOTOS => {
			'CompilationUnit' => 1,
			'FunctionDeclarations' => 2,
			'Pragma' => 8,
			'FunctionDeclaration' => 3,
			'func_decl' => 5,
			'Pragmas' => 4
		}
	},
	{#State 1
		ACTIONS => {
			'' => 10
		}
	},
	{#State 2
		ACTIONS => {
			'FUNCTION' => 7,
			'EXTERN' => 9
		},
		DEFAULT => -174,
		GOTOS => {
			'FunctionDeclaration' => 11,
			'func_decl' => 5
		}
	},
	{#State 3
		DEFAULT => -200
	},
	{#State 4
		ACTIONS => {
			'' => -173,
			'USE' => 6,
			'error' => 13,
			'FUNCTION' => 7,
			'EXTERN' => 9
		},
		GOTOS => {
			'FunctionDeclarations' => 12,
			'Pragma' => 14,
			'FunctionDeclaration' => 3,
			'func_decl' => 5
		}
	},
	{#State 5
		ACTIONS => {
			'IDENTIFIER' => 16,
			'error' => 17,
			")" => 18
		},
		GOTOS => {
			'FormalParameterList' => 15
		}
	},
	{#State 6
		ACTIONS => {
			'URL' => 19,
			'error' => 26,
			'ACCESS' => 24,
			'META' => 20
		},
		GOTOS => {
			'ExternalCompilationUnitPragma' => 25,
			'AccessControlPragma' => 21,
			'PragmaDeclaration' => 23,
			'MetaPragma' => 22
		}
	},
	{#State 7
		ACTIONS => {
			'IDENTIFIER' => 27,
			'error' => 28
		}
	},
	{#State 8
		DEFAULT => -175
	},
	{#State 9
		ACTIONS => {
			'FUNCTION' => 30,
			'error' => 29
		}
	},
	{#State 10
		DEFAULT => 0
	},
	{#State 11
		DEFAULT => -201
	},
	{#State 12
		ACTIONS => {
			'FUNCTION' => 7,
			'EXTERN' => 9
		},
		DEFAULT => -171,
		GOTOS => {
			'FunctionDeclaration' => 11,
			'func_decl' => 5
		}
	},
	{#State 13
		DEFAULT => -172
	},
	{#State 14
		DEFAULT => -176
	},
	{#State 15
		ACTIONS => {
			'error' => 32,
			"," => 31,
			")" => 33
		}
	},
	{#State 16
		DEFAULT => -169
	},
	{#State 17
		DEFAULT => -165
	},
	{#State 18
		ACTIONS => {
			'error' => 36,
			"{" => 35
		},
		GOTOS => {
			'Block' => 34
		}
	},
	{#State 19
		ACTIONS => {
			'IDENTIFIER' => 37
		}
	},
	{#State 20
		ACTIONS => {
			'HTTP' => 38,
			'NAME' => 40,
			'USER' => 44
		},
		GOTOS => {
			'MetaSpecifier' => 39,
			'MetaUserAgent' => 42,
			'MetaName' => 41,
			'MetaHttpEquiv' => 43
		}
	},
	{#State 21
		DEFAULT => -181
	},
	{#State 22
		DEFAULT => -182
	},
	{#State 23
		ACTIONS => {
			";" => 45,
			'error' => 46
		}
	},
	{#State 24
		ACTIONS => {
			'DOMAIN' => 48,
			'PATH' => 47
		},
		GOTOS => {
			'AccessControlSpecifier' => 49
		}
	},
	{#State 25
		DEFAULT => -180
	},
	{#State 26
		DEFAULT => -178
	},
	{#State 27
		ACTIONS => {
			"(" => 50,
			'error' => 51
		}
	},
	{#State 28
		DEFAULT => -159
	},
	{#State 29
		DEFAULT => -156
	},
	{#State 30
		ACTIONS => {
			'IDENTIFIER' => 52,
			'error' => 53
		}
	},
	{#State 31
		ACTIONS => {
			'IDENTIFIER' => 54
		}
	},
	{#State 32
		DEFAULT => -166
	},
	{#State 33
		ACTIONS => {
			'error' => 56,
			"{" => 35
		},
		GOTOS => {
			'Block' => 55
		}
	},
	{#State 34
		ACTIONS => {
			";" => 57
		},
		DEFAULT => -164
	},
	{#State 35
		ACTIONS => {
			"}" => 59,
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'IF' => 94,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'WHILE' => 115,
			"--" => 96,
			'FLOAT_LITERAL' => 95,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 114,
			'BreakStatement' => 82,
			'Expression' => 116,
			'ExternalScriptFunctionCall' => 118,
			'Literal' => 117,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'StatementList' => 90,
			'ForStatement' => 122
		}
	},
	{#State 36
		DEFAULT => -168
	},
	{#State 37
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'StringLiteral' => 123
		}
	},
	{#State 38
		ACTIONS => {
			'EQUIV' => 124
		}
	},
	{#State 39
		DEFAULT => -188
	},
	{#State 40
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'MetaPropertyName' => 127,
			'StringLiteral' => 126,
			'MetaBody' => 125
		}
	},
	{#State 41
		DEFAULT => -189
	},
	{#State 42
		DEFAULT => -191
	},
	{#State 43
		DEFAULT => -190
	},
	{#State 44
		ACTIONS => {
			'AGENT' => 128
		}
	},
	{#State 45
		DEFAULT => -177
	},
	{#State 46
		DEFAULT => -179
	},
	{#State 47
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'StringLiteral' => 129
		}
	},
	{#State 48
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'StringLiteral' => 130
		}
	},
	{#State 49
		DEFAULT => -184
	},
	{#State 50
		DEFAULT => -155
	},
	{#State 51
		DEFAULT => -160
	},
	{#State 52
		ACTIONS => {
			"(" => 132,
			'error' => 131
		}
	},
	{#State 53
		DEFAULT => -157
	},
	{#State 54
		DEFAULT => -170
	},
	{#State 55
		ACTIONS => {
			";" => 133
		},
		DEFAULT => -162
	},
	{#State 56
		DEFAULT => -167
	},
	{#State 57
		DEFAULT => -163
	},
	{#State 58
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 134,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 59
		DEFAULT => -103
	},
	{#State 60
		ACTIONS => {
			"<" => 136,
			">=" => 137,
			"<=" => 138,
			">" => 139
		},
		DEFAULT => -59
	},
	{#State 61
		DEFAULT => -96
	},
	{#State 62
		ACTIONS => {
			"%" => 140,
			"*" => 141,
			'DIV' => 142,
			"/" => 143
		},
		DEFAULT => -47
	},
	{#State 63
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 144,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 64
		DEFAULT => -100
	},
	{#State 65
		DEFAULT => -30
	},
	{#State 66
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 145,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 67
		ACTIONS => {
			"&&" => 146
		},
		DEFAULT => -70
	},
	{#State 68
		ACTIONS => {
			";" => 148,
			'error' => 147
		}
	},
	{#State 69
		DEFAULT => -14
	},
	{#State 70
		DEFAULT => -90
	},
	{#State 71
		DEFAULT => -75
	},
	{#State 72
		DEFAULT => -42
	},
	{#State 73
		ACTIONS => {
			"&" => 149
		},
		DEFAULT => -64
	},
	{#State 74
		ACTIONS => {
			"(" => 151,
			'error' => 150
		}
	},
	{#State 75
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 152,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 76
		DEFAULT => -1
	},
	{#State 77
		ACTIONS => {
			"#" => 153
		}
	},
	{#State 78
		DEFAULT => -97
	},
	{#State 79
		DEFAULT => -17
	},
	{#State 80
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 154,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 81
		ACTIONS => {
			"." => 155
		}
	},
	{#State 82
		DEFAULT => -99
	},
	{#State 83
		DEFAULT => -3
	},
	{#State 84
		DEFAULT => -122
	},
	{#State 85
		ACTIONS => {
			">>" => 156,
			">>>" => 157,
			"<<" => 158
		},
		DEFAULT => -54
	},
	{#State 86
		DEFAULT => -15
	},
	{#State 87
		DEFAULT => -8
	},
	{#State 88
		DEFAULT => -7
	},
	{#State 89
		DEFAULT => -6
	},
	{#State 90
		ACTIONS => {
			"}" => 159,
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'error' => 160,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 161,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 91
		ACTIONS => {
			";" => 163,
			'error' => 162
		}
	},
	{#State 92
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 164,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 93
		DEFAULT => -4
	},
	{#State 94
		ACTIONS => {
			"(" => 166,
			'error' => 165
		}
	},
	{#State 95
		DEFAULT => -2
	},
	{#State 96
		ACTIONS => {
			'IDENTIFIER' => 167
		}
	},
	{#State 97
		ACTIONS => {
			"-" => 58,
			";" => 169,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 168,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 170,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 98
		ACTIONS => {
			"*=" => 171,
			"div=" => 178,
			"|=" => 172,
			"&=" => 179,
			"--" => 180,
			"-=" => 181,
			"/=" => 182,
			"<<=" => 174,
			"(" => -21,
			"." => -23,
			"%=" => 183,
			"^=" => 175,
			">>=" => 176,
			"++" => 184,
			"=" => 186,
			"+=" => 185,
			">>>=" => 177,
			"#" => -22
		},
		DEFAULT => -9,
		GOTOS => {
			'AssignmentOperator' => 173
		}
	},
	{#State 99
		DEFAULT => -5
	},
	{#State 100
		DEFAULT => -95
	},
	{#State 101
		ACTIONS => {
			"^" => 187
		},
		DEFAULT => -66
	},
	{#State 102
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 188,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 189,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 103
		DEFAULT => -93
	},
	{#State 104
		ACTIONS => {
			'IDENTIFIER' => 192,
			'error' => 191
		},
		GOTOS => {
			'VariableDeclaration' => 193,
			'VariableDeclarationList' => 190
		}
	},
	{#State 105
		ACTIONS => {
			"||" => 195,
			"?" => 194
		},
		DEFAULT => -72
	},
	{#State 106
		DEFAULT => -92
	},
	{#State 107
		ACTIONS => {
			"(" => 197
		},
		GOTOS => {
			'Arguments' => 196
		}
	},
	{#State 108
		DEFAULT => -114
	},
	{#State 109
		ACTIONS => {
			"!=" => 199,
			"==" => 198
		},
		DEFAULT => -62
	},
	{#State 110
		ACTIONS => {
			'IDENTIFIER' => 200
		}
	},
	{#State 111
		DEFAULT => -94
	},
	{#State 112
		ACTIONS => {
			"-" => 58,
			";" => 202,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 201,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 203,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 113
		ACTIONS => {
			"|" => 204
		},
		DEFAULT => -68
	},
	{#State 114
		DEFAULT => -104
	},
	{#State 115
		ACTIONS => {
			"(" => 206,
			'error' => 205
		}
	},
	{#State 116
		ACTIONS => {
			";" => 209,
			'error' => 208,
			"," => 207
		}
	},
	{#State 117
		DEFAULT => -10
	},
	{#State 118
		DEFAULT => -16
	},
	{#State 119
		DEFAULT => -33
	},
	{#State 120
		DEFAULT => -98
	},
	{#State 121
		ACTIONS => {
			"-" => 210,
			"+" => 211
		},
		DEFAULT => -50
	},
	{#State 122
		DEFAULT => -123
	},
	{#State 123
		DEFAULT => -183
	},
	{#State 124
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'MetaPropertyName' => 127,
			'StringLiteral' => 126,
			'MetaBody' => 212
		}
	},
	{#State 125
		DEFAULT => -192
	},
	{#State 126
		DEFAULT => -197
	},
	{#State 127
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'MetaContent' => 214,
			'StringLiteral' => 213
		}
	},
	{#State 128
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'MetaPropertyName' => 127,
			'StringLiteral' => 126,
			'MetaBody' => 215
		}
	},
	{#State 129
		DEFAULT => -186
	},
	{#State 130
		ACTIONS => {
			'PATH' => 216
		},
		DEFAULT => -185
	},
	{#State 131
		DEFAULT => -158
	},
	{#State 132
		DEFAULT => -154
	},
	{#State 133
		DEFAULT => -161
	},
	{#State 134
		DEFAULT => -39
	},
	{#State 135
		ACTIONS => {
			"--" => 180,
			"(" => -21,
			"." => -23,
			"++" => 184,
			"#" => -22
		},
		DEFAULT => -9
	},
	{#State 136
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'ShiftExpression' => 217,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 137
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'ShiftExpression' => 218,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 138
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'ShiftExpression' => 219,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 139
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'ShiftExpression' => 220,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 140
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 221,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 141
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 222,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 142
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 223,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 143
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 224,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 144
		DEFAULT => -41
	},
	{#State 145
		DEFAULT => -34
	},
	{#State 146
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 225,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121
		}
	},
	{#State 147
		DEFAULT => -147
	},
	{#State 148
		DEFAULT => -146
	},
	{#State 149
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 226,
			'LibraryFunctionCall' => 79,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'ExternalScriptFunctionCall' => 118,
			'Literal' => 117,
			'StringLiteral' => 83,
			'PostfixExpression' => 119,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121
		}
	},
	{#State 150
		DEFAULT => -131
	},
	{#State 151
		ACTIONS => {
			"-" => 58,
			";" => 229,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 227,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 228,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 230,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 152
		DEFAULT => -38
	},
	{#State 153
		ACTIONS => {
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'FunctionName' => 232
		}
	},
	{#State 154
		DEFAULT => -35
	},
	{#State 155
		ACTIONS => {
			'IDENTIFIER' => 231
		},
		GOTOS => {
			'FunctionName' => 233
		}
	},
	{#State 156
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 234,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 157
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 235,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 158
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 236,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 159
		DEFAULT => -101
	},
	{#State 160
		DEFAULT => -102
	},
	{#State 161
		DEFAULT => -105
	},
	{#State 162
		DEFAULT => -149
	},
	{#State 163
		DEFAULT => -148
	},
	{#State 164
		DEFAULT => -40
	},
	{#State 165
		DEFAULT => -119
	},
	{#State 166
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 237,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 238,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 167
		DEFAULT => -37
	},
	{#State 168
		DEFAULT => -140
	},
	{#State 169
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 239,
			")" => 240,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 241,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 170
		ACTIONS => {
			";" => 243,
			'error' => 242,
			"," => 207
		}
	},
	{#State 171
		DEFAULT => -78
	},
	{#State 172
		DEFAULT => -88
	},
	{#State 173
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 244,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 174
		DEFAULT => -83
	},
	{#State 175
		DEFAULT => -87
	},
	{#State 176
		DEFAULT => -84
	},
	{#State 177
		DEFAULT => -85
	},
	{#State 178
		DEFAULT => -89
	},
	{#State 179
		DEFAULT => -86
	},
	{#State 180
		DEFAULT => -32
	},
	{#State 181
		DEFAULT => -82
	},
	{#State 182
		DEFAULT => -79
	},
	{#State 183
		DEFAULT => -80
	},
	{#State 184
		DEFAULT => -31
	},
	{#State 185
		DEFAULT => -81
	},
	{#State 186
		DEFAULT => -77
	},
	{#State 187
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 245,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'ExternalScriptFunctionCall' => 118,
			'Literal' => 117,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121
		}
	},
	{#State 188
		DEFAULT => -12
	},
	{#State 189
		ACTIONS => {
			'error' => 246,
			"," => 207,
			")" => 247
		}
	},
	{#State 190
		ACTIONS => {
			";" => 250,
			'error' => 249,
			"," => 248
		}
	},
	{#State 191
		DEFAULT => -107
	},
	{#State 192
		ACTIONS => {
			"=" => 252
		},
		DEFAULT => -112,
		GOTOS => {
			'VariableInitializer' => 251
		}
	},
	{#State 193
		DEFAULT => -109
	},
	{#State 194
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 253,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 195
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 254,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121
		}
	},
	{#State 196
		DEFAULT => -18
	},
	{#State 197
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			")" => 256,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'ArgumentList' => 257,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 255,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 198
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'RelationalExpression' => 258,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'ShiftExpression' => 85,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 199
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'RelationalExpression' => 259,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'ShiftExpression' => 85,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 200
		DEFAULT => -36
	},
	{#State 201
		DEFAULT => -152
	},
	{#State 202
		DEFAULT => -150
	},
	{#State 203
		ACTIONS => {
			";" => 261,
			'error' => 260,
			"," => 207
		}
	},
	{#State 204
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 262,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121
		}
	},
	{#State 205
		DEFAULT => -125
	},
	{#State 206
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 263,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 264,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 207
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 265,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 208
		DEFAULT => -116
	},
	{#State 209
		DEFAULT => -115
	},
	{#State 210
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 266,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 211
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'FunctionName' => 107,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 267,
			'PrimaryExpression' => 69,
			'LibraryFunctionCall' => 79,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'LibraryName' => 81,
			'CallExpression' => 65
		}
	},
	{#State 212
		DEFAULT => -193
	},
	{#State 213
		DEFAULT => -198
	},
	{#State 214
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		DEFAULT => -196,
		GOTOS => {
			'MetaScheme' => 268,
			'StringLiteral' => 269
		}
	},
	{#State 215
		DEFAULT => -194
	},
	{#State 216
		ACTIONS => {
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88
		},
		GOTOS => {
			'StringLiteral' => 270
		}
	},
	{#State 217
		ACTIONS => {
			">>" => 156,
			">>>" => 157,
			"<<" => 158
		},
		DEFAULT => -55
	},
	{#State 218
		ACTIONS => {
			">>" => 156,
			">>>" => 157,
			"<<" => 158
		},
		DEFAULT => -58
	},
	{#State 219
		ACTIONS => {
			">>" => 156,
			">>>" => 157,
			"<<" => 158
		},
		DEFAULT => -57
	},
	{#State 220
		ACTIONS => {
			">>" => 156,
			">>>" => 157,
			"<<" => 158
		},
		DEFAULT => -56
	},
	{#State 221
		DEFAULT => -46
	},
	{#State 222
		DEFAULT => -43
	},
	{#State 223
		DEFAULT => -45
	},
	{#State 224
		DEFAULT => -44
	},
	{#State 225
		ACTIONS => {
			"|" => 204
		},
		DEFAULT => -69
	},
	{#State 226
		ACTIONS => {
			"!=" => 199,
			"==" => 198
		},
		DEFAULT => -63
	},
	{#State 227
		DEFAULT => -132
	},
	{#State 228
		ACTIONS => {
			'IDENTIFIER' => 192,
			'error' => 272
		},
		GOTOS => {
			'VariableDeclaration' => 193,
			'VariableDeclarationList' => 271
		}
	},
	{#State 229
		DEFAULT => -129
	},
	{#State 230
		ACTIONS => {
			";" => 274,
			'error' => 273,
			"," => 207
		}
	},
	{#State 231
		DEFAULT => -21
	},
	{#State 232
		ACTIONS => {
			"(" => 197
		},
		GOTOS => {
			'Arguments' => 275
		}
	},
	{#State 233
		ACTIONS => {
			"(" => 197
		},
		GOTOS => {
			'Arguments' => 276
		}
	},
	{#State 234
		ACTIONS => {
			"-" => 210,
			"+" => 211
		},
		DEFAULT => -52
	},
	{#State 235
		ACTIONS => {
			"-" => 210,
			"+" => 211
		},
		DEFAULT => -53
	},
	{#State 236
		ACTIONS => {
			"-" => 210,
			"+" => 211
		},
		DEFAULT => -51
	},
	{#State 237
		DEFAULT => -120
	},
	{#State 238
		ACTIONS => {
			'error' => 277,
			"," => 207,
			")" => 278
		}
	},
	{#State 239
		DEFAULT => -144
	},
	{#State 240
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 279,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 241
		ACTIONS => {
			'error' => 280,
			"," => 207,
			")" => 281
		}
	},
	{#State 242
		DEFAULT => -141
	},
	{#State 243
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 282,
			")" => 283,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Expression' => 284,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AssignmentExpression' => 70,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 244
		DEFAULT => -76
	},
	{#State 245
		ACTIONS => {
			"&" => 149
		},
		DEFAULT => -65
	},
	{#State 246
		DEFAULT => -13
	},
	{#State 247
		DEFAULT => -11
	},
	{#State 248
		ACTIONS => {
			'IDENTIFIER' => 192
		},
		GOTOS => {
			'VariableDeclaration' => 285
		}
	},
	{#State 249
		DEFAULT => -108
	},
	{#State 250
		DEFAULT => -106
	},
	{#State 251
		DEFAULT => -111
	},
	{#State 252
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 135,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'ConditionalExpression' => 286,
			'UnaryExpression' => 72,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 253
		ACTIONS => {
			":" => 287,
			'error' => 288
		}
	},
	{#State 254
		ACTIONS => {
			"&&" => 146
		},
		DEFAULT => -71
	},
	{#State 255
		DEFAULT => -27
	},
	{#State 256
		DEFAULT => -24
	},
	{#State 257
		ACTIONS => {
			'error' => 290,
			"," => 289,
			")" => 291
		}
	},
	{#State 258
		ACTIONS => {
			"<" => 136,
			">=" => 137,
			"<=" => 138,
			">" => 139
		},
		DEFAULT => -60
	},
	{#State 259
		ACTIONS => {
			"<" => 136,
			">=" => 137,
			"<=" => 138,
			">" => 139
		},
		DEFAULT => -61
	},
	{#State 260
		DEFAULT => -153
	},
	{#State 261
		DEFAULT => -151
	},
	{#State 262
		ACTIONS => {
			"^" => 187
		},
		DEFAULT => -67
	},
	{#State 263
		DEFAULT => -126
	},
	{#State 264
		ACTIONS => {
			'error' => 292,
			"," => 207,
			")" => 293
		}
	},
	{#State 265
		DEFAULT => -91
	},
	{#State 266
		ACTIONS => {
			"%" => 140,
			"*" => 141,
			'DIV' => 142,
			"/" => 143
		},
		DEFAULT => -49
	},
	{#State 267
		ACTIONS => {
			"%" => 140,
			"*" => 141,
			'DIV' => 142,
			"/" => 143
		},
		DEFAULT => -48
	},
	{#State 268
		DEFAULT => -195
	},
	{#State 269
		DEFAULT => -199
	},
	{#State 270
		DEFAULT => -187
	},
	{#State 271
		ACTIONS => {
			";" => 295,
			'error' => 294,
			"," => 248
		}
	},
	{#State 272
		DEFAULT => -134
	},
	{#State 273
		DEFAULT => -133
	},
	{#State 274
		DEFAULT => -128
	},
	{#State 275
		DEFAULT => -19
	},
	{#State 276
		DEFAULT => -20
	},
	{#State 277
		DEFAULT => -121
	},
	{#State 278
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 296,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 279
		DEFAULT => -139
	},
	{#State 280
		DEFAULT => -145
	},
	{#State 281
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 297,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 282
		DEFAULT => -142
	},
	{#State 283
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 298,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 284
		ACTIONS => {
			'error' => 299,
			"," => 207,
			")" => 300
		}
	},
	{#State 285
		DEFAULT => -110
	},
	{#State 286
		DEFAULT => -113
	},
	{#State 287
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 301,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 288
		DEFAULT => -74
	},
	{#State 289
		ACTIONS => {
			"-" => 58,
			"~" => 92,
			"+" => 75,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'TRUE_LITERAL' => 93,
			'ISVALID' => 80,
			'error' => 303,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'IDENTIFIER' => 98,
			'FALSE_LITERAL' => 99,
			'TYPEOF' => 66,
			"(" => 102,
			'UTF8_STRING_LITERAL' => 87,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'BitwiseANDExpression' => 73,
			'RelationalExpression' => 60,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'MultiplicativeExpression' => 62,
			'EqualityExpression' => 109,
			'LibraryFunctionCall' => 79,
			'BitwiseORExpression' => 113,
			'LibraryName' => 81,
			'CallExpression' => 65,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'BitwiseXORExpression' => 101,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AssignmentExpression' => 302,
			'UnaryExpression' => 72,
			'ConditionalExpression' => 71,
			'AdditiveExpression' => 121,
			'LogicalORExpression' => 105
		}
	},
	{#State 290
		DEFAULT => -26
	},
	{#State 291
		DEFAULT => -25
	},
	{#State 292
		DEFAULT => -127
	},
	{#State 293
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 304,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 294
		DEFAULT => -135
	},
	{#State 295
		DEFAULT => -130
	},
	{#State 296
		ACTIONS => {
			'ELSE' => 305
		},
		DEFAULT => -118
	},
	{#State 297
		DEFAULT => -138
	},
	{#State 298
		DEFAULT => -137
	},
	{#State 299
		DEFAULT => -143
	},
	{#State 300
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 306,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 301
		DEFAULT => -73
	},
	{#State 302
		DEFAULT => -28
	},
	{#State 303
		DEFAULT => -29
	},
	{#State 304
		DEFAULT => -124
	},
	{#State 305
		ACTIONS => {
			"-" => 58,
			'BREAK' => 91,
			";" => 108,
			"~" => 92,
			"+" => 75,
			'FOR' => 74,
			'INTEGER_LITERAL' => 76,
			"++" => 110,
			"!" => 63,
			'RETURN' => 112,
			'TRUE_LITERAL' => 93,
			'IF' => 94,
			'ISVALID' => 80,
			'WHILE' => 115,
			'FLOAT_LITERAL' => 95,
			"--" => 96,
			'FALSE_LITERAL' => 99,
			'IDENTIFIER' => 98,
			'TYPEOF' => 66,
			"{" => 35,
			"(" => 102,
			'CONTINUE' => 68,
			'UTF8_STRING_LITERAL' => 87,
			'VAR' => 104,
			'STRING_LITERAL' => 88,
			'INVALID_LITERAL' => 89
		},
		GOTOS => {
			'RelationalExpression' => 60,
			'IfStatement' => 61,
			'MultiplicativeExpression' => 62,
			'ReturnStatement' => 64,
			'CallExpression' => 65,
			'for_begin' => 97,
			'ExpressionStatement' => 100,
			'BitwiseXORExpression' => 101,
			'LogicalANDExpression' => 67,
			'PrimaryExpression' => 69,
			'VariableStatement' => 103,
			'AssignmentExpression' => 70,
			'ConditionalExpression' => 71,
			'UnaryExpression' => 72,
			'LogicalORExpression' => 105,
			'BitwiseANDExpression' => 73,
			'Block' => 106,
			'FunctionName' => 107,
			'ExternalScriptName' => 77,
			'EqualityExpression' => 109,
			'IterationStatement' => 78,
			'LibraryFunctionCall' => 79,
			'EmptyStatement' => 111,
			'LibraryName' => 81,
			'BitwiseORExpression' => 113,
			'Statement' => 307,
			'BreakStatement' => 82,
			'Expression' => 116,
			'Literal' => 117,
			'ExternalScriptFunctionCall' => 118,
			'PostfixExpression' => 119,
			'StringLiteral' => 83,
			'ContinueStatement' => 120,
			'WhileStatement' => 84,
			'ShiftExpression' => 85,
			'LocalScriptFunctionCall' => 86,
			'AdditiveExpression' => 121,
			'ForStatement' => 122
		}
	},
	{#State 306
		DEFAULT => -136
	},
	{#State 307
		DEFAULT => -117
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'Literal', 1,
sub
#line 49 "parser.yp"
{
            # always positive
            use bigint;
            if ($_[1] > 2147483648) {
                $_[0]->Error("Integer $_[1] is out of range.\n");
                new WAP::wmls::LoadConst($_[0],
                        'TypeDef'           =>  'TYPE_INVALID',
                );
            }
            else {
                new WAP::wmls::LoadConst($_[0],
                        'TypeDef'           =>  'TYPE_INTEGER',
                        'Value'             =>  $_[1]
                );
            }
        }
	],
	[#Rule 2
		 'Literal', 1,
sub
#line 66 "parser.yp"
{
            # always positive
            use bignum;
            if ($_[1] > 3.40282347e+38) {
                $_[0]->Error("Float $_[1] is out of range.\n");
                new WAP::wmls::LoadConst($_[0],
                        'TypeDef'           =>  'TYPE_INVALID',
                );
            }
            else {
                if ($_[1] < 1.17549435e-38) {
                    $_[0]->Warning("Float $_[1] is underflow.\n");
                    $_[1] = 0.0;
                }
                new WAP::wmls::LoadConst($_[0],
                        'TypeDef'           =>  'TYPE_FLOAT',
                        'Value'             =>  $_[1]
                );
            }
        }
	],
	[#Rule 3
		 'Literal', 1, undef
	],
	[#Rule 4
		 'Literal', 1,
sub
#line 89 "parser.yp"
{
            new WAP::wmls::LoadConst($_[0],
                    'TypeDef'           =>  'TYPE_BOOLEAN',
                    'Value'             =>  1
            );
        }
	],
	[#Rule 5
		 'Literal', 1,
sub
#line 96 "parser.yp"
{
            new WAP::wmls::LoadConst($_[0],
                    'TypeDef'           =>  'TYPE_BOOLEAN',
                    'Value'             =>  0
            );
        }
	],
	[#Rule 6
		 'Literal', 1,
sub
#line 103 "parser.yp"
{
            new WAP::wmls::LoadConst($_[0],
                    'TypeDef'           =>  'TYPE_INVALID',
            );
        }
	],
	[#Rule 7
		 'StringLiteral', 1,
sub
#line 112 "parser.yp"
{
            new WAP::wmls::LoadConst($_[0],
                    'TypeDef'           =>  'TYPE_STRING',
                    'Value'             =>  $_[1]
            );
        }
	],
	[#Rule 8
		 'StringLiteral', 1,
sub
#line 119 "parser.yp"
{
            new WAP::wmls::LoadConst($_[0],
                    'TypeDef'           =>  'TYPE_UTF8_STRING',
                    'Value'             =>  $_[1]
            );
        }
	],
	[#Rule 9
		 'PrimaryExpression', 1,
sub
#line 129 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[1]);
            new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
        }
	],
	[#Rule 10
		 'PrimaryExpression', 1, undef
	],
	[#Rule 11
		 'PrimaryExpression', 3,
sub
#line 138 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 12
		 'PrimaryExpression', 2,
sub
#line 142 "parser.yp"
{
            $_[0]->Error("invalid expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 13
		 'PrimaryExpression', 3,
sub
#line 147 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 14
		 'CallExpression', 1, undef
	],
	[#Rule 15
		 'CallExpression', 1, undef
	],
	[#Rule 16
		 'CallExpression', 1, undef
	],
	[#Rule 17
		 'CallExpression', 1, undef
	],
	[#Rule 18
		 'LocalScriptFunctionCall', 2,
sub
#line 166 "parser.yp"
{
            my $nbargs = (defined $_[2]) ? $_[2]->{OpCode}->{Index} : 0;
            my $def = $_[0]->YYData->{symbtab_func}->LookupLocal($_[1]);
            my $call = new WAP::wmls::Call($_[0],
                    'Definition'        =>  $def,
                    'Index'             =>  $nbargs
            );
            (defined $_[2]) ? $_[2]->concat($call) : $call;
        }
	],
	[#Rule 19
		 'ExternalScriptFunctionCall', 4,
sub
#line 179 "parser.yp"
{
            my $nbargs = (defined $_[4]) ? $_[4]->{OpCode}->{Index} : 0;
            my $def = $_[0]->YYData->{symbtab_func}->LookupExternal($_[1], $_[3], $nbargs);
            my $call = new WAP::wmls::CallUrl($_[0],
                    'Definition'        =>  $def,
                    'Url'               =>  $_[0]->YYData->{symbtab_url}->Lookup($_[1])
            );
            (defined $_[4]) ? $_[4]->concat($call) : $call;
        }
	],
	[#Rule 20
		 'LibraryFunctionCall', 4,
sub
#line 192 "parser.yp"
{
            my $nbargs = (defined $_[4]) ? $_[4]->{OpCode}->{Index} : 0;
            my $def = $_[0]->YYData->{symbtab_func}->LookupLibrary($_[1], $_[3], $nbargs)
                    if ($_[0]->YYData->{symbtab_lib}->Lookup($_[1]));
            my $call = new WAP::wmls::CallLib($_[0],
                    'Definition'        =>  $def
            );
            (defined $_[4]) ? $_[4]->concat($call) : $call;
        }
	],
	[#Rule 21
		 'FunctionName', 1, undef
	],
	[#Rule 22
		 'ExternalScriptName', 1, undef
	],
	[#Rule 23
		 'LibraryName', 1, undef
	],
	[#Rule 24
		 'Arguments', 2,
sub
#line 220 "parser.yp"
{
            undef;
        }
	],
	[#Rule 25
		 'Arguments', 3,
sub
#line 224 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 26
		 'Arguments', 3,
sub
#line 228 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 27
		 'ArgumentList', 1,
sub
#line 236 "parser.yp"
{
            $_[1]->configure(
                    'Index'             =>  1   # nb args
            );
        }
	],
	[#Rule 28
		 'ArgumentList', 3,
sub
#line 242 "parser.yp"
{
            $_[1]->concat($_[3]);
            $_[1]->configure(
                    'Index'             =>  $_[1]->{OpCode}->{Index} + 1    # nb args
            );
        }
	],
	[#Rule 29
		 'ArgumentList', 3,
sub
#line 249 "parser.yp"
{
            $_[0]->Error("invalid argument.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 30
		 'PostfixExpression', 1, undef
	],
	[#Rule 31
		 'PostfixExpression', 2,
sub
#line 259 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[1]);
            my $load = new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
            my $incr = new WAP::wmls::IncrVar($_[0],
                    'Definition'        =>  $var
            );
            $load->concat($incr);
        }
	],
	[#Rule 32
		 'PostfixExpression', 2,
sub
#line 270 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[1]);
            my $load = new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
            my $decr = new WAP::wmls::DecrVar($_[0],
                    'Definition'        =>  $var
            );
            $load->concat($decr);
        }
	],
	[#Rule 33
		 'UnaryExpression', 1, undef
	],
	[#Rule 34
		 'UnaryExpression', 2,
sub
#line 286 "parser.yp"
{
            BuildUnop($_[0], $_[1], $_[2]);
        }
	],
	[#Rule 35
		 'UnaryExpression', 2,
sub
#line 290 "parser.yp"
{
            BuildUnop($_[0], $_[1], $_[2]);
        }
	],
	[#Rule 36
		 'UnaryExpression', 2,
sub
#line 294 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[2]);
            my $incr = new WAP::wmls::IncrVar($_[0],
                    'Definition'        =>  $var
            );
            my $load = new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
            $incr->concat($load);
        }
	],
	[#Rule 37
		 'UnaryExpression', 2,
sub
#line 305 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[2]);
            my $decr = new WAP::wmls::DecrVar($_[0],
                    'Definition'        =>  $var
            );
            my $load = new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
            $decr->concat($load);
        }
	],
	[#Rule 38
		 'UnaryExpression', 2,
sub
#line 316 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 39
		 'UnaryExpression', 2,
sub
#line 320 "parser.yp"
{
            BuildUnop($_[0], $_[1], $_[2]);
        }
	],
	[#Rule 40
		 'UnaryExpression', 2,
sub
#line 324 "parser.yp"
{
            BuildUnop($_[0], $_[1], $_[2]);
        }
	],
	[#Rule 41
		 'UnaryExpression', 2,
sub
#line 328 "parser.yp"
{
            BuildUnop($_[0], $_[1], $_[2]);
        }
	],
	[#Rule 42
		 'MultiplicativeExpression', 1, undef
	],
	[#Rule 43
		 'MultiplicativeExpression', 3,
sub
#line 337 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 44
		 'MultiplicativeExpression', 3,
sub
#line 341 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 45
		 'MultiplicativeExpression', 3,
sub
#line 345 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 46
		 'MultiplicativeExpression', 3,
sub
#line 349 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 47
		 'AdditiveExpression', 1, undef
	],
	[#Rule 48
		 'AdditiveExpression', 3,
sub
#line 358 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 49
		 'AdditiveExpression', 3,
sub
#line 362 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 50
		 'ShiftExpression', 1, undef
	],
	[#Rule 51
		 'ShiftExpression', 3,
sub
#line 371 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 52
		 'ShiftExpression', 3,
sub
#line 375 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 53
		 'ShiftExpression', 3,
sub
#line 379 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 54
		 'RelationalExpression', 1, undef
	],
	[#Rule 55
		 'RelationalExpression', 3,
sub
#line 388 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 56
		 'RelationalExpression', 3,
sub
#line 392 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 57
		 'RelationalExpression', 3,
sub
#line 396 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 58
		 'RelationalExpression', 3,
sub
#line 400 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 59
		 'EqualityExpression', 1, undef
	],
	[#Rule 60
		 'EqualityExpression', 3,
sub
#line 409 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 61
		 'EqualityExpression', 3,
sub
#line 413 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 62
		 'BitwiseANDExpression', 1, undef
	],
	[#Rule 63
		 'BitwiseANDExpression', 3,
sub
#line 422 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 64
		 'BitwiseXORExpression', 1, undef
	],
	[#Rule 65
		 'BitwiseXORExpression', 3,
sub
#line 431 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 66
		 'BitwiseORExpression', 1, undef
	],
	[#Rule 67
		 'BitwiseORExpression', 3,
sub
#line 440 "parser.yp"
{
            BuildBinop($_[0], $_[1], $_[2], $_[3]);
        }
	],
	[#Rule 68
		 'LogicalANDExpression', 1, undef
	],
	[#Rule 69
		 'LogicalANDExpression', 3,
sub
#line 449 "parser.yp"
{
            BuildLogop($_[0], $_[1], new WAP::wmls::ScAnd($_[0]), $_[3]);
        }
	],
	[#Rule 70
		 'LogicalORExpression', 1, undef
	],
	[#Rule 71
		 'LogicalORExpression', 3,
sub
#line 458 "parser.yp"
{
            BuildLogop($_[0], $_[1], new WAP::wmls::ScOr($_[0]), $_[3]);
        }
	],
	[#Rule 72
		 'ConditionalExpression', 1, undef
	],
	[#Rule 73
		 'ConditionalExpression', 5,
sub
#line 467 "parser.yp"
{
            BuildIfElse($_[0], $_[1], $_[3], $_[5]);
        }
	],
	[#Rule 74
		 'ConditionalExpression', 4,
sub
#line 471 "parser.yp"
{
            $_[0]->Error("':' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 75
		 'AssignmentExpression', 1, undef
	],
	[#Rule 76
		 'AssignmentExpression', 3,
sub
#line 481 "parser.yp"
{
            my $asg;
            my $var = $_[0]->YYData->{symbtab_var}->Lookup($_[1]);
            if      ($_[2] eq '=') {
                my $store1 = new WAP::wmls::StoreVar($_[0],
                        'Definition'        =>  $var
                );
                $asg = $_[3]->concat($store1);
            }
            elsif ($_[2] eq '+=') {
                my $add = new WAP::wmls::AddAsg($_[0],
                        'Definition'        =>  $var
                );
                $asg = $_[3]->concat($add);
            }
            elsif ($_[2] eq '-=') {
                my $sub = new WAP::wmls::SubAsg($_[0],
                        'Definition'        =>  $var
                );
                $asg = $_[3]->concat($sub);
            }
            else {
                my $load1 = new WAP::wmls::LoadVar($_[0],
                        'Definition'        =>  $var
                );
                my $binop = BuildBinop($_[0], $load1, $_[2], $_[3]);
                my $store2 = new WAP::wmls::StoreVar($_[0],
                        'Definition'        =>  $var
                );
                $asg = $binop->concat($store2);
            }
            my $load2 = new WAP::wmls::LoadVar($_[0],
                    'Definition'        =>  $var
            );
            $asg->concat($load2);
        }
	],
	[#Rule 77
		 'AssignmentOperator', 1, undef
	],
	[#Rule 78
		 'AssignmentOperator', 1,
sub
#line 523 "parser.yp"
{
            '*';
        }
	],
	[#Rule 79
		 'AssignmentOperator', 1,
sub
#line 527 "parser.yp"
{
            '/';
        }
	],
	[#Rule 80
		 'AssignmentOperator', 1,
sub
#line 531 "parser.yp"
{
            '%';
        }
	],
	[#Rule 81
		 'AssignmentOperator', 1, undef
	],
	[#Rule 82
		 'AssignmentOperator', 1, undef
	],
	[#Rule 83
		 'AssignmentOperator', 1,
sub
#line 539 "parser.yp"
{
            '<<';
        }
	],
	[#Rule 84
		 'AssignmentOperator', 1,
sub
#line 543 "parser.yp"
{
            '>>';
        }
	],
	[#Rule 85
		 'AssignmentOperator', 1,
sub
#line 547 "parser.yp"
{
            '>>>';
        }
	],
	[#Rule 86
		 'AssignmentOperator', 1,
sub
#line 551 "parser.yp"
{
            '&';
        }
	],
	[#Rule 87
		 'AssignmentOperator', 1,
sub
#line 555 "parser.yp"
{
            '^';
        }
	],
	[#Rule 88
		 'AssignmentOperator', 1,
sub
#line 559 "parser.yp"
{
            '|';
        }
	],
	[#Rule 89
		 'AssignmentOperator', 1,
sub
#line 563 "parser.yp"
{
            'DIV';
        }
	],
	[#Rule 90
		 'Expression', 1, undef
	],
	[#Rule 91
		 'Expression', 3,
sub
#line 572 "parser.yp"
{
            $_[1]->concat(new WAP::wmls::Pop($_[0]));
            $_[1]->concat($_[3]);
        }
	],
	[#Rule 92
		 'Statement', 1, undef
	],
	[#Rule 93
		 'Statement', 1, undef
	],
	[#Rule 94
		 'Statement', 1, undef
	],
	[#Rule 95
		 'Statement', 1, undef
	],
	[#Rule 96
		 'Statement', 1, undef
	],
	[#Rule 97
		 'Statement', 1, undef
	],
	[#Rule 98
		 'Statement', 1, undef
	],
	[#Rule 99
		 'Statement', 1, undef
	],
	[#Rule 100
		 'Statement', 1, undef
	],
	[#Rule 101
		 'Block', 3,
sub
#line 601 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 102
		 'Block', 3,
sub
#line 605 "parser.yp"
{
            $_[0]->Error("'\x7d' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 103
		 'Block', 2,
sub
#line 610 "parser.yp"
{
            undef;
        }
	],
	[#Rule 104
		 'StatementList', 1, undef
	],
	[#Rule 105
		 'StatementList', 2,
sub
#line 619 "parser.yp"
{
            if (! defined $_[1]) {
                $_[2];
            }
            else {
                if (! defined $_[2]) {
                    $_[1];
                }
                else {
                    $_[1]->concat($_[2]);
                }
            }
        }
	],
	[#Rule 106
		 'VariableStatement', 3,
sub
#line 636 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 107
		 'VariableStatement', 2,
sub
#line 640 "parser.yp"
{
            $_[0]->Error("invalid variable declaration.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 108
		 'VariableStatement', 3,
sub
#line 645 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 109
		 'VariableDeclarationList', 1, undef
	],
	[#Rule 110
		 'VariableDeclarationList', 3,
sub
#line 655 "parser.yp"
{
            if (! defined $_[1]) {
                $_[3];
            }
            else {
                if (! defined $_[3]) {
                    $_[1];
                }
                else {
                    $_[1]->concat($_[3]);
                }
            }
        }
	],
	[#Rule 111
		 'VariableDeclaration', 2,
sub
#line 672 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->InsertLocal($_[1]);
            my $store = new WAP::wmls::StoreVar($_[0],
                    'Definition'        =>  $var
            );
            $_[2]->concat($store);
        }
	],
	[#Rule 112
		 'VariableDeclaration', 1,
sub
#line 680 "parser.yp"
{
            $_[0]->YYData->{symbtab_var}->InsertLocal($_[1]);
            undef;
        }
	],
	[#Rule 113
		 'VariableInitializer', 2,
sub
#line 688 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 114
		 'EmptyStatement', 1,
sub
#line 695 "parser.yp"
{
            undef;
        }
	],
	[#Rule 115
		 'ExpressionStatement', 2,
sub
#line 702 "parser.yp"
{
            $_[1]->concat(new WAP::wmls::Pop($_[0]));
        }
	],
	[#Rule 116
		 'ExpressionStatement', 2,
sub
#line 706 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 117
		 'IfStatement', 7,
sub
#line 714 "parser.yp"
{
            BuildIfElse($_[0], $_[3], $_[5], $_[7]);
        }
	],
	[#Rule 118
		 'IfStatement', 5,
sub
#line 718 "parser.yp"
{
            BuildIf($_[0], $_[3], $_[5]);
        }
	],
	[#Rule 119
		 'IfStatement', 2,
sub
#line 722 "parser.yp"
{
            $_[0]->Error("'(' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 120
		 'IfStatement', 3,
sub
#line 727 "parser.yp"
{
            $_[0]->Error("invalid expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 121
		 'IfStatement', 4,
sub
#line 732 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 122
		 'IterationStatement', 1, undef
	],
	[#Rule 123
		 'IterationStatement', 1, undef
	],
	[#Rule 124
		 'WhileStatement', 5,
sub
#line 747 "parser.yp"
{
            BuildFor($_[0], undef, $_[3], undef, $_[5]);
        }
	],
	[#Rule 125
		 'WhileStatement', 2,
sub
#line 751 "parser.yp"
{
            $_[0]->Error("'(' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 126
		 'WhileStatement', 3,
sub
#line 756 "parser.yp"
{
            $_[0]->Error("invalid expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 127
		 'WhileStatement', 4,
sub
#line 761 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 128
		 'for_begin', 4,
sub
#line 769 "parser.yp"
{
            $_[3]->concat(new WAP::wmls::Pop($_[0]));
        }
	],
	[#Rule 129
		 'for_begin', 3,
sub
#line 773 "parser.yp"
{
            undef;
        }
	],
	[#Rule 130
		 'for_begin', 5,
sub
#line 777 "parser.yp"
{
            $_[4];
        }
	],
	[#Rule 131
		 'for_begin', 2,
sub
#line 781 "parser.yp"
{
            $_[0]->Error("'(' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 132
		 'for_begin', 3,
sub
#line 786 "parser.yp"
{
            $_[0]->Error("invalid init expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 133
		 'for_begin', 4,
sub
#line 791 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 134
		 'for_begin', 4,
sub
#line 796 "parser.yp"
{
            $_[0]->Error("invalid variable declaration.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 135
		 'for_begin', 5,
sub
#line 801 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 136
		 'ForStatement', 6,
sub
#line 809 "parser.yp"
{
            my $upd = $_[4]->concat(new WAP::wmls::Pop($_[0]));
            BuildFor($_[0], $_[1], $_[2], $upd, $_[6]);
        }
	],
	[#Rule 137
		 'ForStatement', 5,
sub
#line 814 "parser.yp"
{
            BuildFor($_[0], $_[1], $_[2], undef, $_[5]);
        }
	],
	[#Rule 138
		 'ForStatement', 5,
sub
#line 818 "parser.yp"
{
            my $upd = $_[3]->concat(new WAP::wmls::Pop($_[0]));
            BuildFor($_[0], $_[1], undef, $upd, $_[5]);
        }
	],
	[#Rule 139
		 'ForStatement', 4,
sub
#line 823 "parser.yp"
{
            BuildFor($_[0], $_[1], undef, undef, $_[4]);
        }
	],
	[#Rule 140
		 'ForStatement', 2,
sub
#line 827 "parser.yp"
{
            $_[0]->Error("invalid control expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 141
		 'ForStatement', 3,
sub
#line 832 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 142
		 'ForStatement', 4,
sub
#line 837 "parser.yp"
{
            $_[0]->Error("invalid update expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 143
		 'ForStatement', 5,
sub
#line 842 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 144
		 'ForStatement', 3,
sub
#line 847 "parser.yp"
{
            $_[0]->Error("invalid update expression.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 145
		 'ForStatement', 4,
sub
#line 852 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 146
		 'ContinueStatement', 2,
sub
#line 860 "parser.yp"
{
            new WAP::wmls::Jump($_[0],
                    'TypeDef'           =>  'LABEL_CONTINUE'
            );
        }
	],
	[#Rule 147
		 'ContinueStatement', 2,
sub
#line 866 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 148
		 'BreakStatement', 2,
sub
#line 874 "parser.yp"
{
            new WAP::wmls::Jump($_[0],
                    'TypeDef'           =>  'LABEL_BREAK'
            );
        }
	],
	[#Rule 149
		 'BreakStatement', 2,
sub
#line 880 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 150
		 'ReturnStatement', 2,
sub
#line 888 "parser.yp"
{
            new WAP::wmls::ReturnES($_[0]);
        }
	],
	[#Rule 151
		 'ReturnStatement', 3,
sub
#line 892 "parser.yp"
{
            $_[2]->concat(new WAP::wmls::Return($_[0]));
        }
	],
	[#Rule 152
		 'ReturnStatement', 2,
sub
#line 896 "parser.yp"
{
            $_[0]->Error("Missing term.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 153
		 'ReturnStatement', 3,
sub
#line 901 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 154
		 'func_decl', 4,
sub
#line 909 "parser.yp"
{
            $_[0]->YYData->{symbtab_func}->InsertLocal($_[3], 'PUBLIC_FUNC');
        }
	],
	[#Rule 155
		 'func_decl', 3,
sub
#line 913 "parser.yp"
{
            $_[0]->YYData->{symbtab_func}->InsertLocal($_[2], 'PRIVATE_FUNC');
        }
	],
	[#Rule 156
		 'func_decl', 2,
sub
#line 917 "parser.yp"
{
            $_[0]->Error("function excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 157
		 'func_decl', 3,
sub
#line 922 "parser.yp"
{
            $_[0]->Error("invalid function name.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 158
		 'func_decl', 4,
sub
#line 927 "parser.yp"
{
            $_[0]->Error("'(' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 159
		 'func_decl', 2,
sub
#line 932 "parser.yp"
{
            $_[0]->Error("invalid function name.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 160
		 'func_decl', 3,
sub
#line 937 "parser.yp"
{
            $_[0]->Error("'(' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 161
		 'FunctionDeclaration', 5,
sub
#line 945 "parser.yp"
{
            new WAP::wmls::Function($_[0],
                    'Definition'        =>  $_[1],
                    'Param'             =>  $_[2],
                    'Value'             =>  $_[4]
            );
        }
	],
	[#Rule 162
		 'FunctionDeclaration', 4,
sub
#line 953 "parser.yp"
{
            new WAP::wmls::Function($_[0],
                    'Definition'        =>  $_[1],
                    'Param'             =>  $_[2],
                    'Value'             =>  $_[4]
            );
        }
	],
	[#Rule 163
		 'FunctionDeclaration', 4,
sub
#line 961 "parser.yp"
{
            new WAP::wmls::Function($_[0],
                    'Definition'        =>  $_[1],
                    'Value'             =>  $_[3]
            );
        }
	],
	[#Rule 164
		 'FunctionDeclaration', 3,
sub
#line 968 "parser.yp"
{
            new WAP::wmls::Function($_[0],
                    'Definition'        =>  $_[1],
                    'Value'             =>  $_[3]
            );
        }
	],
	[#Rule 165
		 'FunctionDeclaration', 2,
sub
#line 975 "parser.yp"
{
            $_[0]->Error("invalid parameters.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 166
		 'FunctionDeclaration', 3,
sub
#line 980 "parser.yp"
{
            $_[0]->Error("')' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 167
		 'FunctionDeclaration', 4,
sub
#line 985 "parser.yp"
{
            $_[0]->Error("block statement expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 168
		 'FunctionDeclaration', 3,
sub
#line 990 "parser.yp"
{
            $_[0]->Error("block statement expected.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 169
		 'FormalParameterList', 1,
sub
#line 998 "parser.yp"
{
            my $var = $_[0]->YYData->{symbtab_var}->InsertArg($_[1], 0);
            new WAP::wmls::Argument($_[0],
                    'Definition'        =>  $var,
                    'Index'             =>  1           # nb args
            );
        }
	],
	[#Rule 170
		 'FormalParameterList', 3,
sub
#line 1006 "parser.yp"
{
            my $idx = $_[1]->{OpCode}->{Index};
            $_[1]->{OpCode}->{Index} ++;                # nb args
            my $var = $_[0]->YYData->{symbtab_var}->InsertArg($_[3], $idx);
            my $arg = new WAP::wmls::Argument($_[0],
                    'Definition'        =>  $var,
            );
            $_[1]->concat($arg);
        }
	],
	[#Rule 171
		 'CompilationUnit', 2,
sub
#line 1019 "parser.yp"
{
            $_[0]->YYData->{PragmaList} = $_[1];
            $_[0]->YYData->{FunctionList} = $_[2];
        }
	],
	[#Rule 172
		 'CompilationUnit', 2,
sub
#line 1024 "parser.yp"
{
            $_[0]->YYData->{PragmaList} = $_[1];
            $_[0]->YYData->{FunctionList} = undef;
            $_[0]->Error("function declaration excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 173
		 'CompilationUnit', 1,
sub
#line 1031 "parser.yp"
{
            $_[0]->YYData->{PragmaList} = $_[1];
            $_[0]->YYData->{FunctionList} = undef;
            $_[0]->Error("function declaration excepted.\n");
        }
	],
	[#Rule 174
		 'CompilationUnit', 1,
sub
#line 1037 "parser.yp"
{
            $_[0]->YYData->{PragmaList} = undef;
            $_[0]->YYData->{FunctionList} = $_[1];
        }
	],
	[#Rule 175
		 'Pragmas', 1, undef
	],
	[#Rule 176
		 'Pragmas', 2,
sub
#line 1047 "parser.yp"
{
            $_[1]->concat($_[2]);
        }
	],
	[#Rule 177
		 'Pragma', 3,
sub
#line 1054 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 178
		 'Pragma', 2,
sub
#line 1058 "parser.yp"
{
            $_[0]->Error("invalid pragma.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 179
		 'Pragma', 3,
sub
#line 1063 "parser.yp"
{
            $_[0]->Error("';' excepted.\n");
            $_[0]->YYErrok();
        }
	],
	[#Rule 180
		 'PragmaDeclaration', 1, undef
	],
	[#Rule 181
		 'PragmaDeclaration', 1,
sub
#line 1073 "parser.yp"
{
            if (exists $_[0]->YYData->{AccessControlPragma}) {
                $_[0]->Error("multiple access control pragma.\n");
                $_[0]->YYData->{AccessControlPragma} ++;
            }
            else {
                $_[0]->YYData->{AccessControlPragma} = 1;
            }
            $_[1];
        }
	],
	[#Rule 182
		 'PragmaDeclaration', 1, undef
	],
	[#Rule 183
		 'ExternalCompilationUnitPragma', 3,
sub
#line 1089 "parser.yp"
{
            new WAP::wmls::Url($_[0],
                    'Value'             =>  $_[3],
                    'Definition'        =>  $_[0]->YYData->{symbtab_url}->Insert($_[2])
            );
        }
	],
	[#Rule 184
		 'AccessControlPragma', 2,
sub
#line 1099 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 185
		 'AccessControlSpecifier', 2,
sub
#line 1106 "parser.yp"
{
            new WAP::wmls::AccessDomain($_[0],
                    'Value'             =>  $_[2],
            );
        }
	],
	[#Rule 186
		 'AccessControlSpecifier', 2,
sub
#line 1112 "parser.yp"
{
            new WAP::wmls::AccessPath($_[0],
                    'Value'             =>  $_[2]
            );
        }
	],
	[#Rule 187
		 'AccessControlSpecifier', 4,
sub
#line 1118 "parser.yp"
{
            my $domain = new WAP::wmls::AccessDomain($_[0],
                    'Value'             =>  $_[2],
            );
            my $path = new WAP::wmls::AccessPath($_[0],
                    'Value'             =>  $_[4],
            );
            $domain->concat($path);
        }
	],
	[#Rule 188
		 'MetaPragma', 2,
sub
#line 1131 "parser.yp"
{
            $_[2];
        }
	],
	[#Rule 189
		 'MetaSpecifier', 1, undef
	],
	[#Rule 190
		 'MetaSpecifier', 1, undef
	],
	[#Rule 191
		 'MetaSpecifier', 1, undef
	],
	[#Rule 192
		 'MetaName', 2,
sub
#line 1147 "parser.yp"
{
            new WAP::wmls::MetaName($_[0],
                    'Value'             =>  $_[2],
            );
        }
	],
	[#Rule 193
		 'MetaHttpEquiv', 3,
sub
#line 1156 "parser.yp"
{
            new WAP::wmls::MetaHttpEquiv($_[0],
                    'Value'             =>  $_[3],
            );
        }
	],
	[#Rule 194
		 'MetaUserAgent', 3,
sub
#line 1165 "parser.yp"
{
            new WAP::wmls::MetaUserAgent($_[0],
                    'Value'             =>  $_[3],
            );
        }
	],
	[#Rule 195
		 'MetaBody', 3,
sub
#line 1174 "parser.yp"
{
            $_[2]->concat($_[3]);
            $_[1]->concat($_[2]);
        }
	],
	[#Rule 196
		 'MetaBody', 2,
sub
#line 1179 "parser.yp"
{
            $_[1]->concat($_[2]);
        }
	],
	[#Rule 197
		 'MetaPropertyName', 1, undef
	],
	[#Rule 198
		 'MetaContent', 1, undef
	],
	[#Rule 199
		 'MetaScheme', 1, undef
	],
	[#Rule 200
		 'FunctionDeclarations', 1, undef
	],
	[#Rule 201
		 'FunctionDeclarations', 2,
sub
#line 1203 "parser.yp"
{
            $_[1]->concat($_[2]);
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 1208 "parser.yp"


#   Number of rules         : 202
#   Number of terminals     : 80
#   Number of non-terminals : 66
#   Number of states        : 308

use strict;
use warnings;

use WAP::wmls::lexer;
use WAP::wmls::node;

sub BuildUnop {
    my ($parser, $op, $expr) = @_;
    my $unop = new WAP::wmls::UnaryOp($parser,
            'Operator'                  =>  $op
    );
    return $expr->concat($unop);
}

sub BuildBinop {
    my ($parser, $expr1, $op, $expr2) = @_;
    my $binop = new WAP::wmls::BinaryOp($parser,
            'Operator'                  =>  $op,
            'Left'                      =>  $expr1->{Last}
    );
    $expr1->concat($expr2);
    return $expr1->concat($binop);
}

sub BuildLogop {
    my ($parser, $expr1, $logop, $expr2) = @_;
    my $endif = $parser->YYData->{symbtab_label}->Next();
    my $label = new WAP::wmls::Label($parser,
            'Definition'                =>  $endif
    );
    $endif->{Node} = $label;
    my $falsejump = new WAP::wmls::FalseJump($parser,
            'Definition'                =>  $endif
    );
    $endif->{NbUse} ++;
    $expr1->concat($logop);
    $expr1->concat($falsejump);
    $expr1->concat($expr2);
    $expr1->concat(new WAP::wmls::ToBool($parser));
    return $expr1->concat($label);
}

sub BuildIf {
    my ($parser, $expr, $stat) = @_;
    my $endif = $parser->YYData->{symbtab_label}->Next();
    my $label = new WAP::wmls::Label($parser,
            'Definition'                =>  $endif
    );
    $endif->{Node} = $label;
    my $falsejump = new WAP::wmls::FalseJump($parser,
            'Definition'                =>  $endif
    );
    $endif->{NbUse} ++;
    $expr->concat($falsejump);
    $expr->concat($stat) if (defined $stat);
    return $expr->concat($label);
}

sub BuildIfElse {
    my ($parser, $expr, $stat1, $stat2) = @_;
    my $else = $parser->YYData->{symbtab_label}->Next();
    my $endif = $parser->YYData->{symbtab_label}->Next();
    my $label1 = new WAP::wmls::Label($parser,
            'Definition'                =>  $else
    );
    $else->{Node} = $label1;
    my $label2 = new WAP::wmls::Label($parser,
            'Definition'                =>  $endif
    );
    $endif->{Node} = $label2;
    my $falsejump = new WAP::wmls::FalseJump($parser,
            'Definition'                =>  $else
    );
    $else->{NbUse} ++;
    my $jump = new WAP::wmls::Jump($parser,
            'Definition'                =>  $endif
    );
    $endif->{NbUse} ++;
    $expr->concat($falsejump);
    $expr->concat($stat1) if (defined $stat1);
    $expr->concat($jump);
    $expr->concat($label1);
    $expr->concat($stat2) if (defined $stat2);
    return $expr->concat($label2);
}

sub BuildFor {
    my ($parser, $init, $cond, $upd, $stat) = @_;
    my $for;
    my $loop = $parser->YYData->{symbtab_label}->Next();
    my $continue = $parser->YYData->{symbtab_label}->Next();
    my $break = $parser->YYData->{symbtab_label}->Next();
    my $label1 = new WAP::wmls::Label($parser,
            'Definition'                =>  $loop
    );
    $loop->{Node} = $label1;
    my $label2 = new WAP::wmls::Label($parser,
            'Definition'                =>  $continue
    );
    $continue->{Node} = $label2;
    my $label3 = new WAP::wmls::Label($parser,
            'Definition'                =>  $break
    );
    $break->{Node} = $label3;
    if (defined $cond) {
        my $falsejump = new WAP::wmls::FalseJump($parser,
                'Definition'                =>  $break
        );
        $break->{NbUse} ++;
        my $jump = new WAP::wmls::Jump($parser,
                'Definition'                =>  $loop
        );
        $loop->{NbUse} ++;
        $for = (defined $init) ? $init->concat($label1) : $label1;
        $for->concat($cond);
        $for->concat($falsejump);
        $for->concat($stat) if (defined $stat);
        $for->concat($label2);
        $for->concat($upd) if (defined $upd);
        $for->concat($jump);
        $for->concat($label3);
    }
    else {
        my $jump = new WAP::wmls::Jump($parser,
                'Definition'                =>  $loop
        );
        $loop->{NbUse} ++;
        $for = (defined $init) ? $init->concat($label1) : $label1;
        $for->concat($stat) if (defined $stat);
        $for->concat($label2);
        $for->concat($upd) if (defined $upd);
        $for->concat($jump);
        $for->concat($label3);
    }
    for (my $node = $for; defined $node; $node = $node->{Next}) {
        my $opcode = $node->{OpCode};
        if (        $opcode->isa('Jump')
                and exists $opcode->{TypeDef} ) {
            my $type = $opcode->{TypeDef};
            if    ($type eq 'LABEL_CONTINUE') {
                $node->configure(
                        'Definition'        =>  $continue
                );
                $continue->{NbUse} ++;
            }
            elsif ($type eq 'LABEL_BREAK') {
                $node->configure(
                        'Definition'        =>  $break
                );
                $break->{NbUse} ++;
            }
        }
    }
    return $for;
}

sub Run {
    my $parser = shift;

    my $srcname = $parser->YYData->{filename};
    my $enc = $parser->YYData->{encoding};
    open $parser->YYData->{fh}, "<:encoding($enc)", $srcname
        or die "can't open $srcname ($!).\n";

    WAP::wmls::lexer::InitLexico($parser);
    $parser->YYData->{symbtab_var} = new WAP::wmls::SymbTabVar($parser);
    $parser->YYData->{symbtab_lib} = new WAP::wmls::SymbTabLib($parser);
    $parser->YYData->{symbtab_func} = new WAP::wmls::SymbTabFunc($parser);
    $parser->YYData->{symbtab_url} = new WAP::wmls::SymbTabUrl($parser);
    $parser->YYData->{symbtab_label} = new WAP::wmls::SymbTabLabel($parser);
    $parser->InitStandardLibrary();
    $parser->YYData->{doc} = q{};
    $parser->YYData->{lineno} = 1;
    $parser->YYParse(
            yylex   => \&WAP::wmls::lexer::Lexer,
            yyerror => sub { return; }
    );

    close $parser->YYData->{fh};
    delete $parser->{RULES};
    delete $parser->{STATES};
    delete $parser->{STACK};
    return;
}

sub InitStandardLibrary {
    my $parser = shift;
    my $cfg = $INC{'WAP/wmls/parser.pm'};
    $cfg =~ s/parser\.pm$//;
    $cfg .= 'wmlslibs.cfg';
    open my $IN, '<', $cfg
        or warn "can't open $cfg.\n";

    my $lib = undef;
    my $LibID;
    while (<$IN>) {
        if      (/^#.*$/) {
#           print "Comment $_";
        }
        elsif (/^\s*$/) {
#           print "Empty\n";
        }
        elsif (/^\@([A-Z_a-z][0-9A-Z_a-z]*)\s+([0-9]+)\s*$/) {
#           print "Lib $1 $2\n";
            $lib = $1;
            $LibID = $2;
            $parser->YYData->{symbtab_lib}->Insert($lib, 1);
        }
        elsif (/^([A-Z_a-z][0-9A-Z_a-z]*)\s+([0-9]+)\s+([0-9]+)\s*$/) {
#           print "Fct $1 $2 $3\n";
            if (defined $lib) {
                my $symb = $lib . '.' . $1;
                $parser->YYData->{symbtab_func}->InsertLibrary($symb, $LibID, $2, $3);
            }
        }
        else {
            print "cfg? $_";
        }
    }
    close $IN;
    return;
}

sub Error {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= "Syntax error.\n";

    if (exists $parser->YYData->{nb_error}) {
        $parser->YYData->{nb_error} ++;
    }
    else {
        $parser->YYData->{nb_error} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Error: ',$msg
            if (        exists $parser->YYData->{verbose_error}
                    and $parser->YYData->{verbose_error});
    return;
}

sub Warning {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_warning}) {
        $parser->YYData->{nb_warning} ++;
    }
    else {
        $parser->YYData->{nb_warning} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Warning: ',$msg
            if (        exists $parser->YYData->{verbose_warning}
                    and $parser->YYData->{verbose_warning});
    return;
}

sub Info {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_info}) {
        $parser->YYData->{nb_info} ++;
    }
    else {
        $parser->YYData->{nb_info} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Info: ',$msg
            if (        exists $parser->YYData->{verbose_info}
                    and $parser->YYData->{verbose_info});
    return;
}


1;
