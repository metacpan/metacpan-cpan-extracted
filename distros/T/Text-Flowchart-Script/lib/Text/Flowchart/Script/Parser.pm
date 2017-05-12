####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Text::Flowchart::Script::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 1 "grammar.yp"


my $symbol = {};
my $reserved = { map {$_,1} qw/init box relate width height top left bottom right debug pad directed string x_coord y_coord x_pad y_pad reason/ };

my (@ae, @ael, $ae, @expst, $funcstr);
my $pname = 'Text::Flowchart::Script::';

my $result;
sub cat { $result .= join q//,@_ }



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'IDENTIFIER' => 3,
			'STRING_LITERAL' => 10,
			'EOS' => 11,
			'CONSTANT' => 5
		},
		GOTOS => {
			'starting_unit' => 2,
			'statement_list' => 1,
			'funcall_expression' => 7,
			'funcall_preexpression' => 6,
			'statement' => 8,
			'expression' => 9,
			'primary_expression' => 4
		}
	},
	{#State 1
		ACTIONS => {
			'IDENTIFIER' => 3,
			'STRING_LITERAL' => 10,
			'EOS' => 11,
			'CONSTANT' => 5
		},
		DEFAULT => -17,
		GOTOS => {
			'funcall_preexpression' => 6,
			'funcall_expression' => 7,
			'statement' => 12,
			'expression' => 9,
			'primary_expression' => 4
		}
	},
	{#State 2
		ACTIONS => {
			'' => 13
		}
	},
	{#State 3
		DEFAULT => -1
	},
	{#State 4
		ACTIONS => {
			'ASSIGN' => 14
		},
		DEFAULT => -9
	},
	{#State 5
		DEFAULT => -2
	},
	{#State 6
		ACTIONS => {
			'COLON' => 15
		},
		GOTOS => {
			'attribute_expression' => 16,
			'attribute_expression_list' => 17
		}
	},
	{#State 7
		DEFAULT => -11
	},
	{#State 8
		DEFAULT => -15
	},
	{#State 9
		ACTIONS => {
			'EOS' => 18
		}
	},
	{#State 10
		DEFAULT => -3
	},
	{#State 11
		DEFAULT => -13
	},
	{#State 12
		DEFAULT => -16
	},
	{#State 13
		DEFAULT => 0
	},
	{#State 14
		ACTIONS => {
			'IDENTIFIER' => 3,
			'STRING_LITERAL' => 10,
			'CONSTANT' => 5
		},
		GOTOS => {
			'funcall_expression' => 20,
			'funcall_preexpression' => 6,
			'primary_expression' => 19
		}
	},
	{#State 15
		ACTIONS => {
			'IDENTIFIER' => 3,
			'STRING_LITERAL' => 10,
			'CONSTANT' => 5
		},
		GOTOS => {
			'attribute_list' => 22,
			'primary_expression' => 21
		}
	},
	{#State 16
		DEFAULT => -7
	},
	{#State 17
		ACTIONS => {
			'COLON' => 15
		},
		DEFAULT => -10,
		GOTOS => {
			'attribute_expression' => 23
		}
	},
	{#State 18
		DEFAULT => -14
	},
	{#State 19
		DEFAULT => -9
	},
	{#State 20
		DEFAULT => -12
	},
	{#State 21
		DEFAULT => -4
	},
	{#State 22
		ACTIONS => {
			'COMMA' => 24
		},
		DEFAULT => -6
	},
	{#State 23
		DEFAULT => -8
	},
	{#State 24
		ACTIONS => {
			'IDENTIFIER' => 3,
			'STRING_LITERAL' => 10,
			'CONSTANT' => 5
		},
		GOTOS => {
			'primary_expression' => 25
		}
	},
	{#State 25
		DEFAULT => -5
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'primary_expression', 1, undef
	],
	[#Rule 2
		 'primary_expression', 1,
sub
#line 22 "grammar.yp"
{ $_[1]=~s/'(.+)'/$1/go; $_[1] }
	],
	[#Rule 3
		 'primary_expression', 1, undef
	],
	[#Rule 4
		 'attribute_list', 1,
sub
#line 29 "grammar.yp"
{
	push @ae, $symbol->{$_[1]} ? '$'.$pname.'_'.$_[1] : $reserved->{$_[1]} ? "'$_[1]'" : "$_[1]";
	}
	],
	[#Rule 5
		 'attribute_list', 3,
sub
#line 33 "grammar.yp"
{
	push @ae, $symbol->{$_[3]} ? '$'.$pname.'_'.$_[3] : $reserved->{$_[3]} ? "'$_[3]'" : "$_[3]";
	}
	],
	[#Rule 6
		 'attribute_expression', 2,
sub
#line 40 "grammar.yp"
{
	undef $ae;
	$ae = join q/,/, @ae;
	undef @ae;
	}
	],
	[#Rule 7
		 'attribute_expression_list', 1,
sub
#line 49 "grammar.yp"
{
	push @ael, $ae if $ae;
	}
	],
	[#Rule 8
		 'attribute_expression_list', 2,
sub
#line 53 "grammar.yp"
{
	push @ael, $ae if $ae;
	}
	],
	[#Rule 9
		 'funcall_preexpression', 1,
sub
#line 60 "grammar.yp"
{ undef $ae; undef @ae; undef @ael; $_[1] }
	],
	[#Rule 10
		 'funcall_expression', 2,
sub
#line 65 "grammar.yp"
{
	if( $symbol->{$_[1]} ){

	$funcstr = join q//, '$'.$pname.'_'.$_[1], ' = $'.$pname.'chart->box(', join(q//,
	  (@ael  >= 2 ?
	  map{"[$_]"}@ael :
	  @ael
	 )), ");$/";

	return;

	}

	elsif($_[1] eq 'init'){

	cat '$'.$pname.'chart = Text::Flowchart->new('.join( q//, @ael).");$/";
	return;

	}
	elsif($_[1] eq 'box'){

	push @expst, join q//, .'$'.$pname.'chart->box(', join(q//,
	  (@ael  >= 2 ?
	  map{"[$_]"}@ael :
	  @ael
	 )), ");$/";
	return;

	}
	elsif($_[1] eq 'relate'){

	$funcstr = join q//, '$'.$pname.'chart->relate(', join(q/,/,
	  (@ael  >= 2 ? (join q/,/, "[$ael[0]]", "[$ael[1]]", "$ael[2]") :
	  @ael
	 )), ");$/";

	return;

	}
	else{

	cat join q//, '$'.$_[1], ' = $chart->box(', join(q//,
	  (@ael  >= 2 ?
	  map{"[$_]"}@ael :
	  @ael
	 )), ");$/";
	return;
	}

	}
	],
	[#Rule 11
		 'expression', 1,
sub
#line 120 "grammar.yp"
{
	cat $funcstr;
	}
	],
	[#Rule 12
		 'expression', 3,
sub
#line 124 "grammar.yp"
{
	  $symbol->{$_[1]} = 1;
	  cat(  '$'.$pname.'_'.$_[1], @expst ? ' = '.(join q//,@expst) : ";$/");
	  @expst = ();
	}
	],
	[#Rule 13
		 'statement', 1, undef
	],
	[#Rule 14
		 'statement', 2, undef
	],
	[#Rule 15
		 'statement_list', 1, undef
	],
	[#Rule 16
		 'statement_list', 2, undef
	],
	[#Rule 17
		 'starting_unit', 1,
sub
#line 144 "grammar.yp"
{
	 join $/,
	 "use Text::Flowchart; use IO::Scalar; \n",
	 'my $_output; tie *OUT, \'IO::Scalar\', \$_output;',
	 $result, '$Text::Flowchart::Script::chart->draw(*OUT); $output = $_output';
	}
	]
],
                                  @_);
    bless($self,$class);
}

#line 152 "grammar.yp"



1;
