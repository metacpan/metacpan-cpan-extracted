$yysccsid = "@(#)yaccpar 1.8 (Berkeley) 01/20/91 (Perl 2.0 12/31/92)";
#define YYBYACC 1
#line 15 "template.y"

;#
;# Literal block from definition section 
;#

package Text::PORE::Parser;

use Text::PORE::Node;
use Exporter;
@Text::PORE::Parser::ISA = qw(Exporter);
@EXPORT = qw(yyparse setInput);

require ('Text/PORE/template_lexer.pl');

#line 19 "y.tab.pl"
$CLOSE_BRACKET=257;
$NAME=258;
$VAL=259;
$FREETEXT=260;
$OPEN_BRACKET=261;
$SLASH=262;
$IF_ID=263;
$ELSE_ID=264;
$CONTEXT_ID=265;
$LINK_ID=266;
$LIST_ID=267;
$RENDER_ID=268;
$REF_ID=269;
$TABLE_ID=270;
$EXPR=271;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    1,    1,    2,    2,    3,    3,    4,    4,    4,
    6,    6,    6,    5,    5,   12,   12,   13,   13,   13,
   14,   14,   14,    9,    9,    9,   10,   10,   15,   15,
    7,    7,    7,    7,   16,   16,   17,   17,   18,   18,
    8,   11,
);
@yylen = (                                                2,
    1,    0,    2,    1,    1,    1,    2,    1,    1,    1,
    4,    4,    3,    3,    4,    4,    5,    4,    5,    4,
    1,    1,    1,    1,    1,    1,    0,    2,    2,    1,
    3,    5,    4,    6,    4,    4,    4,    5,    4,    4,
    1,    1,
);
@yydefred = (                                             2,
    0,    0,    6,   41,    3,    4,    5,    8,    9,   10,
    0,    2,    2,    7,    0,    0,   21,   22,   23,   24,
   25,   26,    0,   27,    0,    0,   42,   13,    0,    0,
    0,    0,    0,    0,    0,   14,    0,    0,   31,    2,
   36,    0,   35,   28,   12,   11,    0,   16,    0,   15,
    0,    0,   33,    0,    0,    0,   29,   17,    0,    0,
    0,    0,    0,    0,    0,   32,   20,    0,   18,    0,
   37,   40,   39,   34,   19,   38,
);
@yydgoto = (                                              1,
    2,    5,    6,    7,    8,    9,   10,   52,   23,   30,
   28,   12,   36,   24,   44,   13,   39,   40,
);
@yysindex = (                                             0,
    0, -241,    0,    0,    0,    0,    0,    0,    0,    0,
 -169,    0,    0,    0, -235, -245,    0,    0,    0,    0,
    0,    0, -228,    0, -246, -243,    0,    0, -235, -210,
 -235, -210, -206, -231, -192,    0, -231, -207,    0,    0,
    0, -221,    0,    0,    0,    0, -235,    0, -219,    0,
 -240, -209,    0, -179, -184, -215,    0,    0, -235, -188,
 -176, -235, -210, -231, -177,    0,    0, -235,    0, -235,
    0,    0,    0,    0,    0,    0,
);
@yyrindex = (                                             0,
    0,   95,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0, -175,    0,    0,    0,    0,
    0,    0, -175,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0, -191,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0, -175,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,
);
@yygindex = (                                             0,
  -11,    0,    0,    0,    0,    0,    0,   -2,    0,  -15,
  -26,    0,   68,   52,    0,    0,  -25,    0,
);
$YYTABLESIZE=103;
@yytable = (                                             11,
   25,   26,   41,   43,   45,   46,   48,   32,   33,   34,
   29,   53,   37,    3,    4,   59,    3,    4,    3,    4,
   58,   27,   35,   38,   17,   18,   19,   31,   56,    4,
   66,   49,   67,   69,   71,   72,   73,   57,   74,   63,
   64,   75,   51,   76,    3,    4,   27,   42,   15,   47,
   27,   42,   54,   65,   54,   16,   55,   17,   18,   19,
   20,   21,   22,   15,   30,   30,   30,   68,   27,   51,
   16,   62,   17,   18,   19,   20,   21,   22,   15,   70,
   27,   27,   27,   61,   54,   16,   15,   17,   18,   19,
   20,   21,   22,   16,    1,   17,   18,   19,   20,   21,
   22,   50,   60,
);
@yycheck = (                                              2,
   12,   13,   29,   30,   31,   32,   33,   23,   24,  256,
  256,   37,  256,  260,  261,  256,  260,  261,  260,  261,
   47,  257,   25,   26,  265,  266,  267,  256,   40,  261,
   56,   34,   59,   60,   61,   62,   63,  259,   64,   55,
  256,   68,  262,   70,  260,  261,  257,  258,  256,  256,
  257,  258,  262,   56,  262,  263,  264,  265,  266,  267,
  268,  269,  270,  256,  256,  257,  258,  256,  257,  262,
  263,  256,  265,  266,  267,  268,  269,  270,  256,  256,
  257,  257,  258,  263,  262,  263,  256,  265,  266,  267,
  268,  269,  270,  263,    0,  265,  266,  267,  268,  269,
  270,   34,   51,
);
$YYFINAL=1;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=271;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','',"CLOSE_BRACKET","NAME","VAL",
"FREETEXT","OPEN_BRACKET","SLASH","IF_ID","ELSE_ID","CONTEXT_ID","LINK_ID",
"LIST_ID","RENDER_ID","REF_ID","TABLE_ID","EXPR",
);
@yyrule = (
"\$accept : start",
"start : html_file",
"html_file :",
"html_file : html_file html_element",
"html_element : freetext",
"html_element : ind_tag",
"freetext : FREETEXT",
"freetext : freetext FREETEXT",
"ind_tag : container_tag_pair",
"ind_tag : standalone_tag",
"ind_tag : conditional",
"standalone_tag : open_bracket standalone_id pairs close_bracket",
"standalone_tag : open_bracket standalone_id error close_bracket",
"standalone_tag : open_bracket error close_bracket",
"container_tag_pair : start_container_tag html_file end_container_tag",
"container_tag_pair : start_container_tag html_file error end_container_tag",
"start_container_tag : open_bracket container_id pairs close_bracket",
"start_container_tag : open_bracket container_id pairs error close_bracket",
"end_container_tag : open_bracket SLASH container_id close_bracket",
"end_container_tag : open_bracket SLASH container_id error close_bracket",
"end_container_tag : open_bracket SLASH error close_bracket",
"container_id : CONTEXT_ID",
"container_id : LINK_ID",
"container_id : LIST_ID",
"standalone_id : RENDER_ID",
"standalone_id : REF_ID",
"standalone_id : TABLE_ID",
"pairs :",
"pairs : pairs pair",
"pair : NAME VAL",
"pair : NAME",
"conditional : if_tag html_file endif_tag",
"conditional : if_tag html_file else_tag html_file endif_tag",
"conditional : if_tag html_file error endif_tag",
"conditional : if_tag html_file else_tag html_file error endif_tag",
"if_tag : open_bracket IF_ID pairs close_bracket",
"if_tag : open_bracket IF_ID error close_bracket",
"endif_tag : open_bracket SLASH IF_ID close_bracket",
"endif_tag : open_bracket SLASH IF_ID error close_bracket",
"else_tag : open_bracket ELSE_ID pairs close_bracket",
"else_tag : open_bracket ELSE_ID error close_bracket",
"open_bracket : OPEN_BRACKET",
"close_bracket : CLOSE_BRACKET",
);
#endif
sub yyclearin { $yychar = -1; }
sub yyerrok { $yyerrflag = 0; }
$YYSTACKSIZE = $YYSTACKSIZE || $YYMAXDEPTH || 500;
$YYMAXDEPTH = $YYMAXDEPTH || $YYSTACKSIZE || 500;
$yyss[$YYSTACKSIZE] = 0;
$yyvs[$YYSTACKSIZE] = 0;
sub YYERROR { ++$yynerrs; &yy_err_recover; }
sub yy_err_recover
{
  if ($yyerrflag < 3)
  {
    $yyerrflag = 3;
    while (1)
    {
      if (($yyn = $yysindex[$yyss[$yyssp]]) && 
          ($yyn += $YYERRCODE) >= 0 && 
          $yycheck[$yyn] == $YYERRCODE)
      {
#if YYDEBUG
       print "yydebug: state $yyss[$yyssp], error recovery shifting",
             " to state $yytable[$yyn]\n" if $yydebug;
#endif
        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        next yyloop;
      }
      else
      {
#if YYDEBUG
        print "yydebug: error recovery discarding state ",
              $yyss[$yyssp], "\n"  if $yydebug;
#endif
        return(1) if $yyssp <= 0;
        --$yyssp;
        --$yyvsp;
      }
    }
  }
  else
  {
    return (1) if $yychar == 0;
#if YYDEBUG
    if ($yydebug)
    {
      $yys = '';
      if ($yychar <= $YYMAXTOKEN) { $yys = $yyname[$yychar]; }
      if (!$yys) { $yys = 'illegal-symbol'; }
      print "yydebug: state $yystate, error recovery discards ",
            "token $yychar ($yys)\n";
    }
#endif
    $yychar = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse
{
#ifdef YYDEBUG
  if ($yys = $ENV{'YYDEBUG'})
  {
    $yydebug = int($1) if $yys =~ /^(\d)/;
  }
#endif

  $yynerrs = 0;
  $yyerrflag = 0;
  $yychar = (-1);

  $yyssp = 0;
  $yyvsp = 0;
  $yyss[$yyssp] = $yystate = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($yyn = $yydefred[$yystate]);
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }
#if YYDEBUG
        if ($yydebug)
        {
          $yys = '';
          if ($yychar <= $#yyname) { $yys = $yyname[$yychar]; }
          if (!$yys) { $yys = 'illegal-symbol'; };
          print "yydebug: state $yystate, reading $yychar ($yys)\n";
        }
#endif
      }
      if (($yyn = $yysindex[$yystate]) && ($yyn += $yychar) >= 0 &&
              $yycheck[$yyn] == $yychar)
      {
#if YYDEBUG
        print "yydebug: state $yystate, shifting to state ",
              $yytable[$yyn], "\n"  if $yydebug;
#endif
        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        $yychar = (-1);
        --$yyerrflag if $yyerrflag > 0;
        next yyloop;
      }
      if (($yyn = $yyrindex[$yystate]) && ($yyn += $yychar) >= 0 &&
            $yycheck[$yyn] == $yychar)
      {
        $yyn = $yytable[$yyn];
        last yyreduce;
      }
      if (! $yyerrflag) {
        &yyerror('syntax error');
        ++$yynerrs;
      }
      return(1) if &yy_err_recover;
    } # yyreduce
#if YYDEBUG
    print "yydebug: state $yystate, reducing by rule ",
          "$yyn ($yyrule[$yyn])\n"  if $yydebug;
#endif
    $yym = $yylen[$yyn];
    $yyval = $yyvs[$yyvsp+1-$yym];
    switch:
    {
if ($yyn == 1) {
#line 47 "template.y"
{ $yyval = $yyvs[$yyvsp-0];
                                          return $yyval; 
last switch;
} }
if ($yyn == 2) {
#line 54 "template.y"
{ $yyval = new Text::PORE::Node::Queue(getlineno()); 
last switch;
} }
if ($yyn == 3) {
#line 56 "template.y"
{ $yyval = $yyvs[$yyvsp-1];
					  $yyval->enqueue($yyvs[$yyvsp-0]);
					
last switch;
} }
if ($yyn == 4) {
#line 64 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 5) {
#line 65 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 6) {
#line 71 "template.y"
{ $yyval = new Text::PORE::Node::Freetext(getlineno(), $yyvs[$yyvsp-0]); 
last switch;
} }
if ($yyn == 7) {
#line 72 "template.y"
{ $yyval = $yyvs[$yyvsp-1];
					  $yyval->appendText($yyvs[$yyvsp-0]);
					
last switch;
} }
if ($yyn == 8) {
#line 80 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 9) {
#line 81 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 10) {
#line 82 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 11) {
#line 87 "template.y"
{ my($func_name) = lc($yyvs[$yyvsp-2]);
		  my($attrs) = $yyvs[$yyvsp-1];

		  $yyval = new Text::PORE::Node::Standalone(getlineno(), $func_name, $attrs);
		
last switch;
} }
if ($yyn == 12) {
#line 95 "template.y"
{ my($func_name) = lc($yyvs[$yyvsp-2]);

		  yyerror("Garbled open tag $func_name");
		  $yyval = new Text::PORE::Node::Standalone(getlineno(), $func_name, undef);
		
last switch;
} }
if ($yyn == 13) {
#line 103 "template.y"
{
		  yyerror("Unknown standalone tag");
		
last switch;
} }
if ($yyn == 14) {
#line 109 "template.y"
{ $yyval = $yyvs[$yyvsp-2];
		  $yyval->setBody($yyvs[$yyvsp-1]);
		  my($end) = $yyvs[$yyvsp-0];

		  if ($end ne $yyval->{'tag_type'}) {
		      yyerror("$yyval->{'tag_type'} tag starting at line $yyval->{'lineno'} not closed properly");
		  }

		
last switch;
} }
if ($yyn == 15) {
#line 120 "template.y"
{ yyerror("$1->{'tag_type'} tag starting at line $yyval->{'lineno'} not closed properly"); 
last switch;
} }
if ($yyn == 16) {
#line 124 "template.y"
{ my ($func_name) = lc($yyvs[$yyvsp-2]);
		  my ($attrs) = $yyvs[$yyvsp-1];

		  $yyval = new Text::PORE::Node::Container(getlineno(), $func_name, $attrs, undef);
		
last switch;
} }
if ($yyn == 17) {
#line 132 "template.y"
{ my ($func_name) = lc($yyvs[$yyvsp-3]);

		  yyerror("Garbled open tag $func_name");
		  $yyval = new Text::PORE::Node::Container(getlineno(), $func_name, undef, undef);
		
last switch;
} }
if ($yyn == 18) {
#line 140 "template.y"
{ # FIXME? - just returning id now... is that a problem?
                  $yyval = lc($yyvs[$yyvsp-1]);
		
last switch;
} }
if ($yyn == 19) {
#line 146 "template.y"
{ $yyval = lc($yyvs[$yyvsp-3]);
		  yyerror("Garbled open tag $func_name");
		
last switch;
} }
if ($yyn == 20) {
#line 152 "template.y"
{
		  yyerror("Unknown closing tag");
		
last switch;
} }
if ($yyn == 21) {
#line 158 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 22) {
#line 159 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 23) {
#line 160 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 24) {
#line 163 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 25) {
#line 164 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 26) {
#line 165 "template.y"
{ $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 27) {
#line 169 "template.y"
{ $yyval = {}; 
last switch;
} }
if ($yyn == 28) {
#line 170 "template.y"
{ $yyval = $yyvs[$yyvsp-1];
				  $yyval->{$yyvs[$yyvsp-0]->[0]} = $yyvs[$yyvsp-0]->[1];
				
last switch;
} }
if ($yyn == 29) {
#line 176 "template.y"
{ my $attr = lc($yyvs[$yyvsp-1]);
				  $yyval = [$attr, $yyvs[$yyvsp-0]]; 
last switch;
} }
if ($yyn == 30) {
#line 178 "template.y"
{ my $attr = lc($yyvs[$yyvsp-0]);
				  $yyval = [$attr, '1']; 
last switch;
} }
if ($yyn == 31) {
#line 186 "template.y"
{
	    my ($yyval) = $yyvs[$yyvsp-2];
	    my ($if_body) = $yyvs[$yyvsp-1];

	    $yyval->{'if_body'} = $if_body;
	
last switch;
} }
if ($yyn == 32) {
#line 193 "template.y"
{
	    my ($yyval) = $yyvs[$yyvsp-4];
	    my ($if_body) = $yyvs[$yyvsp-3];
	    my ($else_body) = $yyvs[$yyvsp-1];

	    $yyval->{'if_body'} = $if_body;
	    $yyval->{'else_body'} = $else_body;
	
last switch;
} }
if ($yyn == 33) {
#line 203 "template.y"
{ my ($yyval) = $yyvs[$yyvsp-3];
	  my ($if_body) = $yyvs[$yyvsp-2];
	  yyerror("If tag starting at $yyval->{'lineno'} not closed properly");
	  $yyval->{'if_body'} = $if_body;
	
last switch;
} }
if ($yyn == 34) {
#line 210 "template.y"
{ my ($yyval) = $yyvs[$yyvsp-5];
	  my ($if_body) = $yyvs[$yyvsp-4];
	  my ($else_body) = $yyvs[$yyvsp-2];
	  yyerror("If tag starting at $yyval->{'lineno'} not closed properly");
	  $yyval->{'if_body'} = $if_body;
	  $yyval->{'else_body'} = $else_body;
	
last switch;
} }
if ($yyn == 35) {
#line 222 "template.y"
{
	    my($pairs) = $yyvs[$yyvsp-1];
	    $yyval = new Text::PORE::Node::If(getlineno(), $pairs, undef, undef);
	
last switch;
} }
if ($yyn == 36) {
#line 228 "template.y"
{
	    yyerror("Garbled open if tag");
	    $yyval = new Text::PORE::Node::If(getlineno(), undef, undef, undef);
	
last switch;
} }
if ($yyn == 38) {
#line 239 "template.y"
{
	   yyerror("Garbled close if tag");
	
last switch;
} }
if ($yyn == 40) {
#line 248 "template.y"
{
	   yyerror("Garbled open else tag");
	
last switch;
} }
if ($yyn == 41) {
#line 256 "template.y"
{ $INTAG = 1; 
last switch;
} }
if ($yyn == 42) {
#line 262 "template.y"
{ $INTAG = 0; 
last switch;
} }
#line 575 "y.tab.pl"
    } # switch
    $yyssp -= $yym;
    $yystate = $yyss[$yyssp];
    $yyvsp -= $yym;
    $yym = $yylhs[$yyn];
    if ($yystate == 0 && $yym == 0)
    {
#if YYDEBUG
      print "yydebug: after reduction, shifting from state 0 ",
            "to state $YYFINAL\n" if $yydebug;
#endif
      $yystate = $YYFINAL;
      $yyss[++$yyssp] = $YYFINAL;
      $yyvs[++$yyvsp] = $yyval;
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }
#if YYDEBUG
        if ($yydebug)
        {
          $yys = '';
          if ($yychar <= $#yyname) { $yys = $yyname[$yychar]; }
          if (!$yys) { $yys = 'illegal-symbol'; }
          print "yydebug: state $YYFINAL, reading $yychar ($yys)\n";
        }
#endif
      }
      return(0) if $yychar == 0;
      next yyloop;
    }
    if (($yyn = $yygindex[$yym]) && ($yyn += $yystate) >= 0 &&
        $yyn <= $#yycheck && $yycheck[$yyn] == $yystate)
    {
        $yystate = $yytable[$yyn];
    } else {
        $yystate = $yydgoto[$yym];
    }
#if YYDEBUG
    print "yydebug: after reduction, shifting from state ",
        "$yyss[$yyssp] to state $yystate\n" if $yydebug;
#endif
    $yyss[++$yyssp] = $yystate;
    $yyvs[++$yyvsp] = $yyval;
  } # yyloop
} # yyparse
#line 269 "template.y"


# Main Line
# does nothing... main line should be in another program that calls yyparse()

#return value so perl doesn't have a cow
1;
#line 629 "y.tab.pl"
