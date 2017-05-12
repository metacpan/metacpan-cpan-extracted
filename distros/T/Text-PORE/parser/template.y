/**********

#############################################################################
# Program: template.y
# Purpose: Yacc grammar defining the template parser.
#          NOTE: Berkeley yacc v1.8.2 was used as it has the ability to output
#          Perl code. Because we are mixing syntaxes (yacc/C and Perl), some 
#          code can be confusing.  Pay special attention to the context of 
#          comments, as well as special variables ($$, $1, $2, etc).  See 
#          template.pod for further details.
#
#############################################################################

*********/
%{
#
# Literal block from definition section 
#

package Text::PORE::Parser;

use Text::PORE::Node;
use Exporter;
@Text::PORE::Parser::ISA = qw(Exporter);
@EXPORT = qw(yyparse setInput);

require ('Text/PORE/template_lexer.pl');

%}

/* list of tokens returned by yylex */

%token CLOSE_BRACKET NAME VAL FREETEXT OPEN_BRACKET SLASH
%token IF_ID ELSE_ID CONTEXT_ID LINK_ID LIST_ID RENDER_ID REF_ID TABLE_ID EXPR

/* elliminate shift-reduce conflict with recursive def. of freetext */

%left FREETEXT

%%
/****
 Begining of rules section
****/

/* START: base state... merely a placeholder to print out on success */

start: html_file			{ $yyval = $1;
                                          return $yyval; }
        ;

/* HTML_FILE: recursive state to handle arbitrary combinations */
/*  does not print out by default, as it could be within a conditional */

html_file: /* empty */			{ $yyval = new Text::PORE::Node::Queue(getlineno()); }
	| html_file html_element
                                        { $yyval = $1;
					  $yyval->enqueue($2);
					}
	;

/* HTML_ELEMENT: an element here is and template tag, or anything else. */
/* NOTE: precedence is set here to avoid a shift/reduce conflict */

html_element: freetext %prec FREETEXT	{ $yyval = $1; }
	| ind_tag			{ $yyval = $1; }
	;

/* FREETEXT: any arbitrary text... recursive to allow the lexer to */
/* deal with it as it pleases (one char at a time, or all at once) */

freetext: FREETEXT			{ $yyval = new Text::PORE::Node::Freetext(getlineno(), $1); }
	| freetext FREETEXT		{ $yyval = $1;
					  $yyval->appendText($2);
					}
	;

/* IND_TAG: an template tag is a standalone tag or a containter tag. */
/* currently only standalone is implemented. */

ind_tag: container_tag_pair		{ $yyval = $1; }
	| standalone_tag		{ $yyval = $1; }
	| conditional			{ $yyval = $1; }			
	;

standalone_tag:	open_bracket standalone_id pairs close_bracket

		{ my($func_name) = lc($2);
		  my($attrs) = $3;

		  $yyval = new Text::PORE::Node::Standalone(getlineno(), $func_name, $attrs);
		}

		| open_bracket standalone_id error close_bracket

		{ my($func_name) = lc($2);

		  yyerror("Garbled open tag $func_name");
		  $yyval = new Text::PORE::Node::Standalone(getlineno(), $func_name, undef);
		}

		| open_bracket error close_bracket

		{
		  yyerror("Unknown standalone tag");
		}
		;

container_tag_pair: start_container_tag html_file end_container_tag
		{ $yyval = $1;
		  $yyval->setBody($2);
		  my($end) = $3;

		  if ($end ne $yyval->{'tag_type'}) {
		      yyerror("$yyval->{'tag_type'} tag starting at line $yyval->{'lineno'} not closed properly");
		  }

		}
		
		| start_container_tag html_file error end_container_tag
		{ yyerror("$1->{'tag_type'} tag starting at line $yyval->{'lineno'} not closed properly"); }
		;

start_container_tag: open_bracket container_id pairs close_bracket
		{ my ($func_name) = lc($2);
		  my ($attrs) = $3;

		  $yyval = new Text::PORE::Node::Container(getlineno(), $func_name, $attrs, undef);
		}

		| open_bracket container_id pairs error close_bracket

		{ my ($func_name) = lc($2);

		  yyerror("Garbled open tag $func_name");
		  $yyval = new Text::PORE::Node::Container(getlineno(), $func_name, undef, undef);
		}
		;

end_container_tag: open_bracket SLASH container_id close_bracket
		{ # FIXME? - just returning id now... is that a problem?
                  $yyval = lc($3);
		}

		| open_bracket SLASH container_id error close_bracket

		{ $yyval = lc($2);
		  yyerror("Garbled open tag $func_name");
		}

		| open_bracket SLASH error close_bracket

		{
		  yyerror("Unknown closing tag");
		}

		;
	
container_id:	CONTEXT_ID		{ $yyval = $1; }
		| LINK_ID		{ $yyval = $1; }
		| LIST_ID		{ $yyval = $1; }
		;

standalone_id:	RENDER_ID		{ $yyval = $1; }
		| REF_ID		{ $yyval = $1; }
		| TABLE_ID		{ $yyval = $1; }
		;

/* PAIRS: allows for an arbitrary number of NAME=VAL pairs */
pairs: /* empty */		{ $yyval = {}; }
	| pairs pair		{ $yyval = $1;
				  $yyval->{$2->[0]} = $2->[1];
				}
	;

/* PAIR: 'NAME=VAL' or 'NAME' where '=1' is implicit */
pair: NAME VAL			{ my $attr = lc($1);
				  $yyval = [$attr, $2]; }
	| NAME			{ my $attr = lc($1);
				  $yyval = [$attr, '1']; }
	;

/* CONDITIONAL: an if statement with an optional else clause. Has */
/* special syntax rather than generic container tag syntax */

conditional: if_tag html_file endif_tag
        {
	    my ($yyval) = $1;
	    my ($if_body) = $2;

	    $yyval->{'if_body'} = $if_body;
	}
	| if_tag html_file else_tag html_file endif_tag
        {
	    my ($yyval) = $1;
	    my ($if_body) = $2;
	    my ($else_body) = $4;

	    $yyval->{'if_body'} = $if_body;
	    $yyval->{'else_body'} = $else_body;
	}

	| if_tag html_file error endif_tag 
	{ my ($yyval) = $1;
	  my ($if_body) = $2;
	  yyerror("If tag starting at $yyval->{'lineno'} not closed properly");
	  $yyval->{'if_body'} = $if_body;
	}  

	| if_tag html_file else_tag html_file error endif_tag
	{ my ($yyval) = $1;
	  my ($if_body) = $2;
	  my ($else_body) = $4;
	  yyerror("If tag starting at $yyval->{'lineno'} not closed properly");
	  $yyval->{'if_body'} = $if_body;
	  $yyval->{'else_body'} = $else_body;
	}
  	;

/* IF_TAG: the form of an if */

if_tag: open_bracket IF_ID pairs close_bracket
        {
	    my($pairs) = $3;
	    $yyval = new Text::PORE::Node::If(getlineno(), $pairs, undef, undef);
	}

	| open_bracket IF_ID error close_bracket
	{
	    yyerror("Garbled open if tag");
	    $yyval = new Text::PORE::Node::If(getlineno(), undef, undef, undef);
	}
	;

/* ENDIF_TAG: the form of an endif */

endif_tag: open_bracket SLASH IF_ID close_bracket
			
	| open_bracket SLASH IF_ID error close_bracket
	{
	   yyerror("Garbled close if tag");
	}
	;

/* ELSE_TAG: the form of an else */

else_tag: open_bracket ELSE_ID pairs close_bracket
	| open_bracket ELSE_ID error close_bracket
	{
	   yyerror("Garbled open else tag");
	}
	;

/* OPEN_BRACKET: ('<')... sets $INTAG to change the state */
/* of the lexer */

open_bracket:	OPEN_BRACKET		{ $INTAG = 1; }
		;	

/* CLOSE_BRACKET: ('>')... resets $INTAG to change the state */
/* of the lexer */

close_bracket:	CLOSE_BRACKET		{ $INTAG = 0; }
		;

/*****
 End of rules section
*****/

%%

# Main Line
# does nothing... main line should be in another program that calls yyparse()

#return value so perl doesn't have a cow
1;
