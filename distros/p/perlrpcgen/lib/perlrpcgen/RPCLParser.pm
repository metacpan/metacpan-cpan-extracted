"@(#)yaccpar 1.8 (Berkeley) 01/20/91 (JAKE-P5BP-0.5 12/16/96)";
package RPCLParser;

;#   Copyright 1997 Jake Donham <jake@organic.com>

;#   You may distribute under the terms of either the GNU General
;#   Public License or the Artistic License, as specified in the README
;#   file.

;# $Id: RPCLParser.pm,v 1.1 1997/04/30 21:15:18 jake Exp $

use perlrpcgen::RPCL;
$CONST=257;
$IDENT=258;
$CONSTANT=259;
$ENUM=260;
$STRUCT=261;
$TYPE=262;
$UNION=263;
$SWITCH=264;
$CASE=265;
$DEFAULT=266;
$TYPEDEF=267;
$PROGRAM=268;
$VERSION=269;
$OPAQUE=270;
$STRING=271;
$INT=272;
$UNSIGNED=273;
$FLOAT=274;
$DOUBLE=275;
$BOOL=276;
$VOID=277;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    2,    2,    2,    2,    2,    2,    2,    2,    2,
    2,    2,    4,    4,    3,    3,    3,    3,    3,    3,
    3,    3,    3,    3,    3,    3,    3,    3,    5,    8,
    9,    9,    6,   10,   11,   11,    7,   12,   13,   13,
   14,   14,   15,   16,   17,   17,   17,   17,   17,   18,
   19,   19,   20,   21,   21,   22,   23,   23,   23,    1,
    1,
);
@yylen = (                                                2,
    1,    2,    5,    5,    4,    5,    5,    4,    5,    4,
    3,    1,    1,    1,    1,    2,    1,    1,    1,    1,
    1,    1,    1,    1,    1,    2,    2,    2,    2,    3,
    3,    5,    2,    3,    2,    3,    2,    7,    1,    2,
    5,    6,    4,    5,    3,    4,    4,    5,    4,    8,
    1,    2,    8,    1,    2,    8,    1,    1,    1,    1,
    2,
);
@yydefred = (                                             0,
    0,    0,    0,    0,    0,    0,    0,    0,   58,   57,
   59,   60,    0,    0,    0,    0,    0,   25,    0,    0,
    0,    0,    0,   15,    0,   18,   19,   20,    0,    0,
    0,   22,   23,   24,    0,   61,    0,    0,    0,    0,
    0,    0,    0,    0,   28,   29,   26,   33,   27,   37,
    0,    0,   16,   45,    0,    0,    0,    0,    0,    0,
   46,    0,    0,   47,    0,    0,   49,    0,    0,    0,
    0,    0,   11,    0,    0,   51,   44,    0,   30,    0,
   35,   34,    0,   48,    0,   14,   13,    0,    8,    0,
   10,    0,    0,    5,    0,    0,    0,   52,   31,    0,
   36,    0,    6,    7,    9,    3,    4,    0,    0,    0,
    0,   21,    0,    0,   54,    0,   32,    0,    0,    0,
    0,    0,   55,   50,    0,   38,    0,    0,   40,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
   53,   41,    0,   43,    0,   42,    0,   56,
);
@yydgoto = (                                              7,
    8,   30,   31,   88,   32,   33,   34,   39,   60,   41,
   63,   44,  119,  120,  129,    9,   10,   11,   75,   76,
  114,  115,   12,
);
@yysindex = (                                          -161,
 -239, -230,  -38, -222, -187, -216,    0, -161,    0,    0,
    0,    0,  -28,  -79,  -78, -210, -215,    0, -114, -111,
 -229, -208, -206,    0, -217,    0,    0,    0,    0,   -2,
  -37,    0,    0,    0,  -65,    0, -200, -198,    2, -187,
    3,  -78,   23,   16,    0,    0,    0,    0,    0,    0,
  -45,   17,    0,    0,  -44, -180, -190,   21,   30,  -30,
    0,   33, -118,    0,   34, -187,    0, -228,  -56,  -54,
 -228,  -52,    0, -176, -103,    0,    0, -228,    0, -164,
    0,    0,   38,    0,   57,    0,    0,    8,    0,   42,
    0,   46,   18,    0,   48,  -11,   52,    0,    0,   53,
    0,   -8,    0,    0,    0,    0,    0, -207, -143, -228,
 -148,    0, -140, -112,    0,   60,    0, -228,   -5, -225,
   81,   61,    0,    0,   65,    0, -228,   66,    0, -207,
 -134, -187,   68, -187,   86,   69,   70, -187,   71,   72,
    0,    0,   73,    0, -128,    0,   75,    0,
);
@yyrindex = (                                             0,
    0,    0,    0,    0,    0,    0,    0,  135,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,  -39,    0,    0,    0,  -41,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,  -21,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,   11,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,
);
@yygindex = (                                             0,
    0,  -29,  -87,  -46,    0,    0,    0,  118,    0,   -3,
    0,  117,    0,    0,    0,    0,    0,    0,    0,   64,
    0,   27,  142,
);
$YYTABLESIZE=221;
@yytable = (                                             12,
   21,   17,   17,   16,   56,   89,   82,   91,   38,   94,
   62,   40,  122,   80,   69,   72,   48,   12,   13,    2,
  113,   97,   90,   92,   93,   95,  113,   14,   49,   86,
   87,   99,   37,   83,   43,   17,   85,    2,   65,  127,
  128,   35,  135,   38,   40,   68,   71,   42,   43,   51,
   18,   52,   19,   20,   53,   21,   54,   57,   58,   59,
   61,   64,   66,  117,   24,   25,   26,   27,   28,  112,
   18,  125,   19,   20,   67,   21,   70,   73,   74,   77,
  133,   96,   22,   23,   24,   25,   26,   27,   28,   29,
   78,   81,   84,  100,   79,    1,  101,  102,    2,    3,
  103,    4,  137,  104,  139,    5,    6,  105,  143,  107,
  106,  108,  109,  110,  111,  116,  118,  121,  124,  126,
  130,  131,  132,  134,  136,  138,  140,  141,  142,  144,
  147,  146,  145,  148,    1,   39,   46,   50,   98,   18,
  123,   19,   20,   45,   21,   18,   47,   19,   20,   36,
   21,   22,   23,   24,   25,   26,   27,   28,   29,   24,
   25,   26,   27,   28,  112,   74,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,   86,   87,   86,   87,   86,   87,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   21,    0,   17,   15,
   55,
);
@yycheck = (                                             41,
   42,   41,   42,   42,   42,   62,  125,   62,  123,   62,
   40,  123,  125,   44,   60,   60,   20,   59,  258,   41,
  108,  125,   69,   70,   71,   72,  114,  258,  258,  258,
  259,   78,   61,   63,  264,  258,   66,   59,   42,  265,
  266,  258,  130,  123,  123,   91,   91,  258,  264,  258,
  258,  258,  260,  261,  272,  263,   59,  123,  259,  258,
   59,   59,   40,  110,  272,  273,  274,  275,  276,  277,
  258,  118,  260,  261,   59,  263,   60,  258,  269,   59,
  127,  258,  270,  271,  272,  273,  274,  275,  276,  277,
   61,   59,   59,  258,  125,  257,   59,   41,  260,  261,
   93,  263,  132,   62,  134,  267,  268,   62,  138,   62,
   93,  123,   61,   61,  123,  259,  265,  258,   59,  125,
   40,   61,   58,   58,  259,   58,   41,   59,   59,   59,
  259,   59,   61,   59,    0,  125,   19,   21,   75,  258,
  114,  260,  261,  258,  263,  258,  258,  260,  261,    8,
  263,  270,  271,  272,  273,  274,  275,  276,  277,  272,
  273,  274,  275,  276,  277,  269,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,  258,  259,  258,  259,  258,  259,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  258,   -1,  258,  258,
  258,
);
$YYFINAL=7;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=277;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','',"'('","')'","'*'",'',"','",'','','','','','','','','','','','','',"':'","';'",
"'<'","'='","'>'",'','','','','','','','','','','','','','','','','','','','','','','','','','','','',"'['",
'',"']'",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','',"'{'",'',"'}'",
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','',"CONST","IDENT","CONSTANT","ENUM","STRUCT","TYPE","UNION",
"SWITCH","CASE","DEFAULT","TYPEDEF","PROGRAM","VERSION","OPAQUE","STRING","INT",
"UNSIGNED","FLOAT","DOUBLE","BOOL","VOID",
);
@yyrule = (
"\$accept : start",
"start : specification",
"declaration : type_specifier IDENT",
"declaration : type_specifier IDENT '[' value ']'",
"declaration : type_specifier IDENT '<' value '>'",
"declaration : type_specifier IDENT '<' '>'",
"declaration : OPAQUE IDENT '[' value ']'",
"declaration : OPAQUE IDENT '<' value '>'",
"declaration : OPAQUE IDENT '<' '>'",
"declaration : STRING IDENT '<' value '>'",
"declaration : STRING IDENT '<' '>'",
"declaration : type_specifier '*' IDENT",
"declaration : VOID",
"value : CONSTANT",
"value : IDENT",
"type_specifier : INT",
"type_specifier : UNSIGNED INT",
"type_specifier : UNSIGNED",
"type_specifier : FLOAT",
"type_specifier : DOUBLE",
"type_specifier : BOOL",
"type_specifier : VOID",
"type_specifier : enum_type_spec",
"type_specifier : struct_type_spec",
"type_specifier : union_type_spec",
"type_specifier : IDENT",
"type_specifier : STRUCT IDENT",
"type_specifier : UNION IDENT",
"type_specifier : ENUM IDENT",
"enum_type_spec : ENUM enum_body",
"enum_body : '{' enum_list '}'",
"enum_list : IDENT '=' value",
"enum_list : enum_list ',' IDENT '=' value",
"struct_type_spec : STRUCT struct_body",
"struct_body : '{' struct_list '}'",
"struct_list : declaration ';'",
"struct_list : struct_list declaration ';'",
"union_type_spec : UNION union_body",
"union_body : SWITCH '(' declaration ')' '{' switch_body '}'",
"switch_body : case_list",
"switch_body : case_list default",
"case_list : CASE value ':' declaration ';'",
"case_list : case_list CASE value ':' declaration ';'",
"default : DEFAULT ':' declaration ';'",
"constant_def : CONST IDENT '=' CONSTANT ';'",
"type_def : TYPEDEF declaration ';'",
"type_def : ENUM IDENT enum_body ';'",
"type_def : STRUCT IDENT struct_body ';'",
"type_def : STRUCT '*' IDENT struct_body ';'",
"type_def : UNION IDENT union_body ';'",
"program_def : PROGRAM IDENT '{' version_list '}' '=' CONSTANT ';'",
"version_list : version_def",
"version_list : version_list version_def",
"version_def : VERSION IDENT '{' procedure_list '}' '=' CONSTANT ';'",
"procedure_list : procedure_def",
"procedure_list : procedure_list procedure_def",
"procedure_def : type_specifier IDENT '(' type_specifier ')' '=' CONSTANT ';'",
"definition : type_def",
"definition : constant_def",
"definition : program_def",
"specification : definition",
"specification : specification definition",
);
#endif
sub yyclearin { $_[0]->{'yychar'} = -1; }
sub yyerrok { $_[0]->{'yyerrflag'} = 0; }
sub new {
  my $p = {'yylex' => $_[1], 'yyerror' => $_[2], 'yydebug' => $_[3]};
  bless $p, $_[0];
}
sub YYERROR { ++$_[0]->{'yynerrs'}; $_[0]->yy_err_recover; }
sub yy_err_recover {
  my ($p) = @_;
  if ($p->{'yyerrflag'} < 3)
  {
    $p->{'yyerrflag'} = 3;
    while (1)
    {
      if (($p->{'yyn'} = $yysindex[$p->{'yyss'}->[$p->{'yyssp'}]]) && 
          ($p->{'yyn'} += $YYERRCODE) >= 0 && 
          $yycheck[$p->{'yyn'}] == $YYERRCODE)
      {
        warn("yydebug: state " . 
                     $p->{'yyss'}->[$p->{'yyssp'}] . 
                     ", error recovery shifting to state" . 
                     $yytable[$p->{'yyn'}] . "\n") 
                       if $p->{'yydebug'};
        $p->{'yyss'}->[++$p->{'yyssp'}] = 
          $p->{'yystate'} = $yytable[$p->{'yyn'}];
        $p->{'yyvs'}->[++$p->{'yyvsp'}] = $p->{'yylval'};
        next yyloop;
      }
      else
      {
        warn("yydebug: error recovery discarding state ".
              $p->{'yyss'}->[$p->{'yyssp'}]. "\n") 
                if $p->{'yydebug'};
        return(undef) if $p->{'yyssp'} <= 0;
        --$p->{'yyssp'};
        --$p->{'yyvsp'};
      }
    }
  }
  else
  {
    return (undef) if $p->{'yychar'} == 0;
    if ($p->{'yydebug'})
    {
      $p->{'yys'} = '';
      if ($p->{'yychar'} <= $YYMAXTOKEN) { $p->{'yys'} = 
        $yyname[$p->{'yychar'}]; }
      if (!$p->{'yys'}) { $p->{'yys'} = 'illegal-symbol'; }
      warn("yydebug: state " . $p->{'yystate'} . 
                   ", error recovery discards " . 
                   "token " . $p->{'yychar'} . "(" . 
                   $p->{'yys'} . ")\n");
    }
    $p->{'yychar'} = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse {
  my ($p, $s) = @_;
  if ($p->{'yys'} = $ENV{'YYDEBUG'})
  {
    $p->{'yydebug'} = int($1) if $p->{'yys'} =~ /^(\d)/;
  }

  $p->{'yynerrs'} = 0;
  $p->{'yyerrflag'} = 0;
  $p->{'yychar'} = (-1);

  $p->{'yyssp'} = 0;
  $p->{'yyvsp'} = 0;
  $p->{'yyss'}->[$p->{'yyssp'}] = $p->{'yystate'} = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($p->{'yyn'} = $yydefred[$p->{'yystate'}]);
      if ($p->{'yychar'} < 0)
      {
        if ((($p->{'yychar'}, $p->{'yylval'}) = 
            &{$p->{'yylex'}}($s)) < 0) { $p->{'yychar'} = 0; }
        if ($p->{'yydebug'})
        {
          $p->{'yys'} = '';
          if ($p->{'yychar'} <= $#yyname) 
             { $p->{'yys'} = $yyname[$p->{'yychar'}]; }
          if (!$p->{'yys'}) { $p->{'yys'} = 'illegal-symbol'; };
          warn("yydebug: state " . $p->{'yystate'} . 
                       ", reading " . $p->{'yychar'} . " (" . 
                       $p->{'yys'} . ")\n");
        }
      }
      if (($p->{'yyn'} = $yysindex[$p->{'yystate'}]) && 
          ($p->{'yyn'} += $p->{'yychar'}) >= 0 && 
          $yycheck[$p->{'yyn'}] == $p->{'yychar'})
      {
        warn("yydebug: state " . $p->{'yystate'} . 
                     ", shifting to state " .
              $yytable[$p->{'yyn'}] . "\n") if $p->{'yydebug'};
        $p->{'yyss'}->[++$p->{'yyssp'}] = $p->{'yystate'} = 
          $yytable[$p->{'yyn'}];
        $p->{'yyvs'}->[++$p->{'yyvsp'}] = $p->{'yylval'};
        $p->{'yychar'} = (-1);
        --$p->{'yyerrflag'} if $p->{'yyerrflag'} > 0;
        next yyloop;
      }
      if (($p->{'yyn'} = $yyrindex[$p->{'yystate'}]) && 
          ($p->{'yyn'} += $p->{'yychar'}) >= 0 &&
          $yycheck[$p->{'yyn'}] == $p->{'yychar'})
      {
        $p->{'yyn'} = $yytable[$p->{'yyn'}];
        last yyreduce;
      }
      if (! $p->{'yyerrflag'}) {
        &{$p->{'yyerror'}}('syntax error', $s);
        ++$p->{'yynerrs'};
      }
      return(undef) if $p->yy_err_recover;
    } # yyreduce
    warn("yydebug: state " . $p->{'yystate'} . 
                 ", reducing by rule " . 
                 $p->{'yyn'} . " (" . $yyrule[$p->{'yyn'}] . 
                 ")\n") if $p->{'yydebug'};
    $p->{'yym'} = $yylen[$p->{'yyn'}];
    $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}+1-$p->{'yym'}];
if ($p->{'yyn'} == 2) {
{ $p->{'yyval'} = RPCL::Decl->new($p->{'yyvs'}->[$p->{'yyvsp'}-1], $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 3) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeFixedArr->new($p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1]), $p->{'yyvs'}->[$p->{'yyvsp'}-3]); }
}
if ($p->{'yyn'} == 4) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarArr->new($p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1], $p->{'yyvs'}->[$p->{'yyvsp'}-3]), $p->{'yyvs'}->[$p->{'yyvsp'}-3]); }
}
if ($p->{'yyn'} == 5) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarArr->new($p->{'yyvs'}->[$p->{'yyvsp'}-3], undef, $p->{'yyvs'}->[$p->{'yyvsp'}-2]), $p->{'yyvs'}->[$p->{'yyvsp'}-2]); }
}
if ($p->{'yyn'} == 6) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeFixedOpq->new($p->{'yyvs'}->[$p->{'yyvsp'}-1]), $p->{'yyvs'}->[$p->{'yyvsp'}-3]); }
}
if ($p->{'yyn'} == 7) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarOpq->new($p->{'yyvs'}->[$p->{'yyvsp'}-1], $p->{'yyvs'}->[$p->{'yyvsp'}-3]), $p->{'yyvs'}->[$p->{'yyvsp'}-3]); }
}
if ($p->{'yyn'} == 8) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarOpq->new(undef, $p->{'yyvs'}->[$p->{'yyvsp'}-2]), $p->{'yyvs'}->[$p->{'yyvsp'}-2]); }
}
if ($p->{'yyn'} == 9) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarStr->new($p->{'yyvs'}->[$p->{'yyvsp'}-1], $p->{'yyvs'}->[$p->{'yyvsp'}-3]), $p->{'yyvs'}->[$p->{'yyvsp'}-3]); }
}
if ($p->{'yyn'} == 10) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVarStr->new(undef, $p->{'yyvs'}->[$p->{'yyvsp'}-2]), $p->{'yyvs'}->[$p->{'yyvsp'}-2]); }
}
if ($p->{'yyn'} == 11) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypePtr->new($p->{'yyvs'}->[$p->{'yyvsp'}-2]), $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 12) {
{ $p->{'yyval'} = RPCL::Decl->new
			  (RPCL::TypeVoid->new(), undef); }
}
if ($p->{'yyn'} == 13) {
{ $p->{'yyval'} = RPCL::Constant->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 14) {
{ $p->{'yyval'} = RPCL::NamedConstant->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 15) {
{ $p->{'yyval'} = RPCL::TypeInt->new(); }
}
if ($p->{'yyn'} == 16) {
{ $p->{'yyval'} = RPCL::TypeUInt->new(); }
}
if ($p->{'yyn'} == 17) {
{ $p->{'yyval'} = RPCL::TypeUInt->new(); }
}
if ($p->{'yyn'} == 18) {
{ $p->{'yyval'} = RPCL::TypeFloat->new(); }
}
if ($p->{'yyn'} == 19) {
{ $p->{'yyval'} = RPCL::TypeDouble->new(); }
}
if ($p->{'yyn'} == 20) {
{ $p->{'yyval'} = RPCL::TypeBool->new(); }
}
if ($p->{'yyn'} == 21) {
{ $p->{'yyval'} = RPCL::TypeVoid->new(); }
}
if ($p->{'yyn'} == 25) {
{ $p->{'yyval'} = RPCL::TypeName->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 26) {
{ $p->{'yyval'} = RPCL::TypeName->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 27) {
{ $p->{'yyval'} = RPCL::TypeName->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 28) {
{ $p->{'yyval'} = RPCL::TypeName->new($p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 29) {
{ $p->{'yyval'} = RPCL::EnumDef->new(&gensym('enum'), $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 30) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; }
}
if ($p->{'yyn'} == 31) {
{ $p->{'yyval'} = [ RPCL::EnumVal->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-0]) ]; }
}
if ($p->{'yyn'} == 32) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-4]; push(@{$p->{'yyval'}}, RPCL::EnumVal->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-0])); }
}
if ($p->{'yyn'} == 33) {
{ $p->{'yyval'} = RPCL::StructDef->new(&gensym('struct'), $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 34) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; }
}
if ($p->{'yyn'} == 35) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-1] ]; }
}
if ($p->{'yyn'} == 36) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-2]; push(@{$p->{'yyval'}}, $p->{'yyvs'}->[$p->{'yyvsp'}-1]); }
}
if ($p->{'yyn'} == 37) {
{ $p->{'yyval'} = RPCL::UnionDef
			  (&gensym('union'), $p->{'yyvs'}->[$p->{'yyvsp'}-0]->[0], $p->{'yyvs'}->[$p->{'yyvsp'}-0]->[1]); }
}
if ($p->{'yyn'} == 38) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1] ]; }
}
if ($p->{'yyn'} == 39) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-0] ]; }
}
if ($p->{'yyn'} == 40) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; push(@{$p->{'yyval'}}, $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 41) {
{ $p->{'yyval'} = [ RPCL::Case->new($p->{'yyvs'}->[$p->{'yyvsp'}-3], $p->{'yyvs'}->[$p->{'yyvsp'}-1]) ] }
}
if ($p->{'yyn'} == 42) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-5]; push(@{$p->{'yyval'}}, RPCL::Case->new($p->{'yyvs'}->[$p->{'yyvsp'}-3], $p->{'yyvs'}->[$p->{'yyvsp'}-1])); }
}
if ($p->{'yyn'} == 43) {
{ $p->{'yyval'} = RPCL::CaseDefault->new($p->{'yyvs'}->[$p->{'yyvsp'}-1]); }
}
if ($p->{'yyn'} == 44) {
{ $p->{'yyval'} = RPCL::ConstDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-3], $p->{'yyvs'}->[$p->{'yyvsp'}-1]);
			  $main::consts{$p->{'yyvs'}->[$p->{'yyvsp'}-3]} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; }
}
if ($p->{'yyn'} == 45) {
{ $p->{'yyval'} = RPCL::TypedefDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-1]->ident, $p->{'yyvs'}->[$p->{'yyvsp'}-1]->type);
			  $main::types{$p->{'yyvs'}->[$p->{'yyvsp'}-1]->ident} = $p->{'yyval'}; }
}
if ($p->{'yyn'} == 46) {
{ $p->{'yyval'} = RPCL::EnumDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-1]);
			  $main::types{$p->{'yyvs'}->[$p->{'yyvsp'}-2]} = $p->{'yyval'}; }
}
if ($p->{'yyn'} == 47) {
{ $p->{'yyval'} = RPCL::StructDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-1]);
			  $main::types{$p->{'yyvs'}->[$p->{'yyvsp'}-2]} = $p->{'yyval'}; }
}
if ($p->{'yyn'} == 48) {
{ $p->{'yyval'} = RPCL::StructPDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-1]);
			  $main::types{$p->{'yyvs'}->[$p->{'yyvsp'}-2]} = $p->{'yyval'}; }
}
if ($p->{'yyn'} == 49) {
{ $p->{'yyval'} = RPCL::UnionDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-2], $p->{'yyvs'}->[$p->{'yyvsp'}-1]->[0], $p->{'yyvs'}->[$p->{'yyvsp'}-1]->[1]);
			  $main::types{$p->{'yyvs'}->[$p->{'yyvsp'}-2]} = $p->{'yyval'}; }
}
if ($p->{'yyn'} == 50) {
{ $p->{'yyval'} = RPCL::ProgramDef->new($p->{'yyvs'}->[$p->{'yyvsp'}-6], $p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1]); }
}
if ($p->{'yyn'} == 51) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-0] ]; }
}
if ($p->{'yyn'} == 52) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; push(@{$p->{'yyval'}}, $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 53) {
{ $p->{'yyval'} = RPCL::Version->new($p->{'yyvs'}->[$p->{'yyvsp'}-6], $p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1]); }
}
if ($p->{'yyn'} == 54) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-0] ]; }
}
if ($p->{'yyn'} == 55) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; push(@{$p->{'yyval'}}, $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
if ($p->{'yyn'} == 56) {
{ $p->{'yyval'} = RPCL::Procedure->new($p->{'yyvs'}->[$p->{'yyvsp'}-7], $p->{'yyvs'}->[$p->{'yyvsp'}-6], $p->{'yyvs'}->[$p->{'yyvsp'}-4], $p->{'yyvs'}->[$p->{'yyvsp'}-1]); }
}
if ($p->{'yyn'} == 60) {
{ $p->{'yyval'} = [ $p->{'yyvs'}->[$p->{'yyvsp'}-0] ]; }
}
if ($p->{'yyn'} == 61) {
{ $p->{'yyval'} = $p->{'yyvs'}->[$p->{'yyvsp'}-1]; push(@{$p->{'yyval'}}, $p->{'yyvs'}->[$p->{'yyvsp'}-0]); }
}
    $p->{'yyssp'} -= $p->{'yym'};
    $p->{'yystate'} = $p->{'yyss'}->[$p->{'yyssp'}];
    $p->{'yyvsp'} -= $p->{'yym'};
    $p->{'yym'} = $yylhs[$p->{'yyn'}];
    if ($p->{'yystate'} == 0 && $p->{'yym'} == 0)
    {
      warn("yydebug: after reduction, shifting from state 0 ",
            "to state $YYFINAL\n") if $p->{'yydebug'};
      $p->{'yystate'} = $YYFINAL;
      $p->{'yyss'}->[++$p->{'yyssp'}] = $YYFINAL;
      $p->{'yyvs'}->[++$p->{'yyvsp'}] = $p->{'yyval'};
      if ($p->{'yychar'} < 0)
      {
        if ((($p->{'yychar'}, $p->{'yylval'}) = 
            &{$p->{'yylex'}}($s)) < 0) { $p->{'yychar'} = 0; }
        if ($p->{'yydebug'})
        {
          $p->{'yys'} = '';
          if ($p->{'yychar'} <= $#yyname) 
            { $p->{'yys'} = $yyname[$p->{'yychar'}]; }
          if (!$p->{'yys'}) { $p->{'yys'} = 'illegal-symbol'; }
          warn("yydebug: state $YYFINAL, reading " . 
               $p->{'yychar'} . " (" . $p->{'yys'} . ")\n");
        }
      }
      return ($p->{'yyvs'}->[1]) if $p->{'yychar'} == 0;
      next yyloop;
    }
    if (($p->{'yyn'} = $yygindex[$p->{'yym'}]) && 
        ($p->{'yyn'} += $p->{'yystate'}) >= 0 && 
        $p->{'yyn'} <= $#yycheck && 
        $yycheck[$p->{'yyn'}] == $p->{'yystate'})
    {
        $p->{'yystate'} = $yytable[$p->{'yyn'}];
    } else {
        $p->{'yystate'} = $yydgoto[$p->{'yym'}];
    }
    warn("yydebug: after reduction, shifting from state " . 
        $p->{'yyss'}->[$p->{'yyssp'}] . " to state " . 
        $p->{'yystate'} . "\n") if $p->{'yydebug'};
    $p->{'yyss'}[++$p->{'yyssp'}] = $p->{'yystate'};
    $p->{'yyvs'}[++$p->{'yyvsp'}] = $p->{'yyval'};
  } # yyloop
} # yyparse

%keywords =
    ('const'	=> $CONST,
     'enum'	=> $ENUM,
     'struct'	=> $STRUCT,
     'union'	=> $UNION,
     'switch'	=> $SWITCH,
     'case'	=> $CASE,
     'default'	=> $DEFAULT,
     'typedef'	=> $TYPEDEF,
     'program'	=> $PROGRAM,
     'version'	=> $VERSION,
     'opaque'	=> $OPAQUE,
     'string'	=> $STRING,
     'int'	=> $INT,
     'unsigned'	=> $UNSIGNED,
     'float'	=> $FLOAT,
     'double'	=> $DOUBLE,
     'bool'	=> $BOOL,
     'void'	=> $VOID);

%main::consts = ();

sub gensym {
  my ($sym) = @_;
  $sym = 'g' unless $sym;
  return $sym . $gensyms{$sym}++;
}

sub yylex {
  my ($s) = @_;
  my ($c, $val);

AGAIN:

  while (($c = $s->getc) eq ' ' || $c eq "\t" || $c eq "\n") {
  }

  if ($c eq '') {
    return 0;
  }

  elsif ($c eq '%') { # RPCL pass-through character
    while (($c = $s->getc) ne "\n" && $c ne '') {
    }
    $s->ungetc;
    goto AGAIN;
  }

  elsif ($c =~ /[a-zA-Z_]/) {
    $val = $c;
    while (($c = $s->getc) =~ /[0-9a-zA-Z_]/) {
      $val .= $c;
    }
    $s->ungetc;
    if ($keywords{$val}) {
      return $keywords{$val};
    }
    else {
      return ($IDENT, $val);
    }
  }

  elsif ($c =~ /[0-9-]/) {
    $val = $c;
    while (($c = $s->getc) =~ /[0-9]/) {
      $val .= $c;
    }
    $s->ungetc;
    return ($CONSTANT, $val);
  }

  else {
    return ord($c);
  }
}

sub yyerror {
    my ($msg, $s) = @_;
    die "$msg at " . $s->name . " line " . $s->lineno . ".\n";
}

1;
