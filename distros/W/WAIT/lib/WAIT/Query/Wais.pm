
;#                              -*- Mode: Perl -*- 
;# waisquery.y -- 
;# ITIID           : $ITI$ $Header $__Header$
;# Author          : Ulrich Pfeifer
;# Created On      : Fri Sep 13 15:54:19 1996
;# Last Modified By: Ulrich Pfeifer
;# Last Modified On: Sun Nov 22 18:44:28 1998
;# Language        : CPerl
;# Update Count    : 129
;# Status          : Unknown, Use with caution!
;# 
;# Copyright (c) 1996-1997, Ulrich Pfeifer
;# 

package WAIT::Query::Wais;
use WAIT::Query::Base;
use Carp;
use strict;
use vars qw($WORD $PHONIX $SOUNDEX $ASSIGN $FLOAT $OR $AND $NOT $PROX_ORDERED
            $PROX_UNORDERED $PROX_ATLEAST
            $yylval $yyval $YYTABLESIZE $Table
            %TOKEN);
my %VERBOSE ;
no strict 'vars';
$WORD=257;
$PHONIX=258;
$SOUNDEX=259;
$ASSIGN=260;
$FLOAT=261;
$OR=262;
$AND=263;
$NOT=264;
$PROX_ORDERED=265;
$PROX_UNORDERED=266;
$PROX_ATLEAST=267;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    2,    2,    1,    1,    3,    3,    3,    4,    4,
    4,    4,    5,    5,    7,    5,    9,    5,   10,    5,
   11,    5,   12,    5,   13,   13,    8,    8,   14,   14,
   14,   15,   15,   15,   15,   16,   16,   17,   17,    6,
    6,
);
@yylen = (                                                2,
    1,    0,    1,    1,    3,    1,    3,    3,    1,    3,
    3,    2,    1,    3,    0,    6,    0,    4,    0,    4,
    0,    4,    0,    7,    1,    1,    1,    3,    1,    3,
    3,    1,    3,    3,    2,    1,    3,    1,    2,    1,
    3,
);
@yydefred = (                                             0,
    0,   25,   26,    0,    0,    0,    0,    0,    6,    0,
   13,    0,    0,    0,    0,    0,    0,   12,    0,    3,
    0,    0,    0,    0,    0,   39,    0,    0,    0,    0,
    0,    0,   14,    0,    7,    8,   10,   11,   41,    0,
   38,   18,   20,   22,    0,    0,    0,   36,    0,    0,
   29,    0,    0,   35,    0,   16,    0,    0,    0,    0,
    0,    0,   37,    0,   30,   31,   33,   34,   24,
);
@yydgoto = (                                              6,
    7,   21,    8,    9,   10,   11,   28,   49,   29,   15,
   16,   17,   12,   50,   51,   52,   13,
);
@yysindex = (                                           -15,
  -61,    0,    0,   -4,  -15,    0, -257, -248,    0, -239,
    0, -246, -251,    0,   -9,  -25,  -46,    0,  -35,    0,
  -15,  -15,  -15,   -4,   -4,    0, -211,   14, -236, -199,
 -198, -197,    0, -248,    0,    0,    0,    0,    0,  -10,
    0,    0,    0,    0,   18,   53,  -10,    0,  -34, -230,
    0, -226, -186,    0,  -23,    0,  -10,  -10,  -10,   53,
   53,  -20,    0, -230,    0,    0,    0,    0,    0,
);
@yyrindex = (                                             0,
    1,    0,    0,    0,    0,    0,   57,   35,    0,   24,
    0,    0,   12,   60,    0,    0,    0,    0,   42,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,   46,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   42,  -27,
    0,  -38,    0,    0,   42,    0,    0,    0,    0,    0,
    0,    0,    0,  -21,    0,    0,    0,    0,    0,
);
@yygindex = (                                             0,
   67,  -45,   56,   21,    4,    9,    0,   27,    0,    0,
    0,    0,    0,   22,  -11,  -29,    0,
);
$YYTABLESIZE=324;
@yytable = (                                             14,
   38,   32,   32,   57,   20,   33,   56,   18,   27,   57,
   26,   40,   27,   27,   22,   23,   54,   63,   28,   28,
   41,    2,    3,    9,    5,   24,   25,   37,   38,   47,
   67,   68,   58,   59,    4,    5,   31,   42,   60,   61,
   38,   38,   35,   36,   32,    5,   65,   66,   48,   39,
   30,   40,   40,   40,   48,   48,    1,   43,   44,   45,
   19,   53,   21,    9,    9,   48,   48,   48,   48,   48,
   62,   19,   69,   55,    4,    4,   34,    0,   64,    0,
    0,    2,    0,    0,    0,    5,    5,    0,    0,    0,
    0,   23,   47,    0,    0,    0,    2,    0,    0,   15,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   32,   32,
   32,    0,    0,   32,   32,   32,   20,   20,   32,   27,
   27,   27,    0,    0,   27,   28,   28,   28,   20,   27,
   28,    1,    2,    3,    0,   28,   41,    2,    3,    0,
    0,    4,    1,    2,    3,    0,   46,   38,   38,   38,
   38,    0,   38,   38,   38,   38,   38,   38,   40,   40,
   40,    0,    0,   40,   40,   40,   40,   40,   40,    0,
    9,    9,    9,    0,    0,    9,    9,    9,    0,    0,
    9,    4,    4,    4,    0,    0,    4,    0,    2,    2,
    2,    4,    5,    5,    5,    0,    0,    5,    2,   41,
    2,    3,    5,    2,    2,    2,   17,   17,   17,    0,
    0,    0,    0,    2,
);
@yycheck = (                                             61,
    0,   40,   41,   49,  262,   41,   41,    4,  260,   55,
  257,    0,   40,   41,  263,  264,   46,   41,   40,   41,
  257,  258,  259,    0,   40,  265,  266,   24,   25,   40,
   60,   61,  263,  264,    0,   40,   62,   29,  265,  266,
   40,   41,   22,   23,   91,    0,   58,   59,   40,  261,
   60,   40,   41,   40,   46,   47,    0,  257,  257,  257,
   60,   44,   62,   40,   41,   57,   58,   59,   60,   61,
  257,    5,   93,   47,   40,   41,   21,   -1,   57,   -1,
   -1,   40,   -1,   -1,   -1,   40,   41,   -1,   -1,   -1,
   -1,   91,   40,   -1,   -1,   -1,   40,   -1,   -1,   40,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,
  259,   -1,   -1,  262,  263,  264,  262,  262,  267,  257,
  258,  259,   -1,   -1,  262,  257,  258,  259,  262,  267,
  262,  257,  258,  259,   -1,  267,  257,  258,  259,   -1,
   -1,  267,  257,  258,  259,   -1,  267,  257,  258,  259,
  260,   -1,  262,  263,  264,  265,  266,  267,  257,  258,
  259,   -1,   -1,  262,  263,  264,  265,  266,  267,   -1,
  257,  258,  259,   -1,   -1,  262,  263,  264,   -1,   -1,
  267,  257,  258,  259,   -1,   -1,  262,   -1,  257,  258,
  259,  267,  257,  258,  259,   -1,   -1,  262,  267,  257,
  258,  259,  267,  257,  258,  259,  257,  258,  259,   -1,
   -1,   -1,   -1,  267,
);
$YYFINAL=6;



$YYMAXTOKEN=267;

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




        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        next yyloop;
      }
      else
      {




        return(1) if $yyssp <= 0;
        --$yyssp;
        --$yyvsp;
      }
    }
  }
  else
  {
    return (1) if $yychar == 0;

    $yychar = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse
{

  if ($yys = $ENV{'YYDEBUG'})
  {
    $yydebug = int($1) if $yys =~ /^(\d)/;
  }


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

      }
      if (($yyn = $yysindex[$yystate]) && ($yyn += $yychar) >= 0 &&
              $yycheck[$yyn] == $yychar)
      {




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




    $yym = $yylen[$yyn];
    $yyval = $yyvs[$yyvsp+1-$yym];
    switch:
    {
if ($yyn == 5) {
{ $yyval = $yyval->merge($yyvs[$yyvsp-0]); 
last switch;
} }
if ($yyn == 7) {
{$yyval = new WAIT::Query::and $yyvs[$yyvsp-2], $yyvs[$yyvsp-0];
last switch;
} }
if ($yyn == 8) {
{$yyval = new WAIT::Query::not $yyvs[$yyvsp-2], $yyvs[$yyvsp-0];
last switch;
} }
if ($yyn == 14) {
{ $yyval = $yyvs[$yyvsp-1]; 
last switch;
} }
if ($yyn == 15) {
{enter($yyvs[$yyvsp-1]);
last switch;
} }
if ($yyn == 16) {
{leave($yyvs[$yyvsp-5]); $yyval = $yyvs[$yyvsp-1]; 
last switch;
} }
if ($yyn == 17) {
{enter($yyvs[$yyvsp-1]);
last switch;
} }
if ($yyn == 18) {
{leave($yyvs[$yyvsp-3]); $yyval = $yyvs[$yyvsp-0]; 
last switch;
} }
if ($yyn == 19) {
{enter($yyvs[$yyvsp-0]);
last switch;
} }
if ($yyn == 20) {
{$yyval = intervall(undef, $yyvs[$yyvsp-0]); leave($yyvs[$yyvsp-3]);
last switch;
} }
if ($yyn == 21) {
{enter($yyvs[$yyvsp-0]);
last switch;
} }
if ($yyn == 22) {
{$yyval = intervall($yyvs[$yyvsp-0], undef); leave($yyvs[$yyvsp-3]);
last switch;
} }
if ($yyn == 23) {
{enter($yyvs[$yyvsp-0]);
last switch;
} }
if ($yyn == 24) {
{$yyval = intervall($yyvs[$yyvsp-3], $yyvs[$yyvsp-1]); leave($yyvs[$yyvsp-6]);
last switch;
} }
if ($yyn == 28) {
{ $yyval = $yyval->merge($yyvs[$yyvsp-0]); 
last switch;
} }
if ($yyn == 30) {
{$yyval = new WAIT::Query::and $yyvs[$yyvsp-2], $yyvs[$yyvsp-0];
last switch;
} }
if ($yyn == 31) {
{$yyval = new WAIT::Query::not $yyvs[$yyvsp-2], $yyvs[$yyvsp-0];
last switch;
} }
if ($yyn == 37) {
{ $yyval = $yyvs[$yyvsp-1]; 
last switch;
} }
if ($yyn == 38) {
{ $yyval = plain($yyvs[$yyvsp-0]); 
last switch;
} }
if ($yyn == 39) {
{ $yyval = plain($yyvs[$yyvsp-0]); 
last switch;
} }
    } # switch
    $yyssp -= $yym;
    $yystate = $yyss[$yyssp];
    $yyvsp -= $yym;
    $yym = $yylhs[$yyn];
    if ($yystate == 0 && $yym == 0)
    {




      $yystate = $YYFINAL;
      $yyss[++$yyssp] = $YYFINAL;
      $yyvs[++$yyvsp] = $yyval;
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }

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




    $yyss[++$yyssp] = $yystate;
    $yyvs[++$yyvsp] = $yyval;
  } # yyloop
} # yyparse
use strict;
sub yyerror {
  warn "yyerror: @_ $.\n";
}

for (qw(and or not phonix soundex)) {
  my $e = sprintf '$WAIT::Query::Wais::TOKEN{$_} = $%s', uc($_);
  eval $e;
  die $@ if $@ ne '';
  $VERBOSE{$TOKEN{$_}} = $_;
}
$VERBOSE{$WORD} = 'WORD';
my $KEY = join('|', keys %TOKEN);

my $line;

sub yylex1 {
  print "=>$line\n";
  my $token = yylex1();
  my $verbose;
  my $val = (defined $yylval)?",$yylval":'';
  if ($token < 256) {
    $verbose = "'".chr($token)."'";
  } else {
    $verbose = $VERBOSE{$token};
  }
  warn "yylex($token=$verbose$val)\n";
  return $token;
}

my $Intervall = 0;
sub yylex {
  $yylval = undef;
  $line =~ s:^\s+::;
  if ($line =~ s:^($KEY)\b::io) {
    return $TOKEN{$1}
  } elsif ($line =~ s/^(\w+)\s*==?/=/io) {
    $yylval = $1;
    return $WORD;
  } elsif ($line =~ s:^([=()<>])::) {
    return ord($1);
  } elsif ($Intervall and $line =~ s:^,::) {
    return ord(',');
  } elsif ($line =~ s:^\[::) {
    $Intervall = 1;
    return ord('[');
  } elsif ($line =~ s:^\]::) {
    $Intervall = 0;
    return ord(']');
  } elsif ($Intervall and $line =~ s:^([^,\]]+)::) {
    $yylval = $1;
    return $WORD;
  } elsif ($line =~ s:^([^=\[<>()\n\r\t ]+)::) {
    $yylval = $1;
    return $WORD;
  }
  return 0;
}

my @FLD;

use vars qw(%FLD);

sub fields {
  if (ref $FLD[-1]) {
    @{$FLD[-1]}
  } else {
    $FLD[-1];
  }
}


sub enter {
  my $field = shift;

  if ($FLD{$field}) {
    push @FLD, $FLD{$field};
  } else {
    croak "Unknown field name: $field";
  }
}

sub leave {
  pop @FLD;
}

sub plain {
  my $word = shift;

  if ($word =~ s:\*$::) {
    prefix($word);
  } else {
    new WAIT::Query::Base $Table, $FLD[-1], Plain => $word;
  }
}

sub prefix {
  my $word = shift;
  my ($ff, @fld) = fields();
  my $raw = $Table->prefix($ff, $word);
  for $ff (@fld) {
    my $new = $Table->prefix($ff, $word);
    $raw->merge($new);
  }
  new WAIT::Query::Base ($Table, $FLD[-1], Raw => $raw);
}

sub intervall {
  my ($left, $right) = @_;
  my ($ff, @fld) = fields();
  my $raw = $Table->intervall($ff, $left, $right);
  for $ff (@fld) {
    my $new = $Table->intervall($ff, $left, $right);
    $raw->merge($new);
  }
  new WAIT::Query::Base ($Table, $FLD[-1], Raw => $raw);
}

use Text::Abbrev;
sub query {
  local($Table) = shift;
  $line = shift;

  my @fields = $Table->fields;

  @FLD = (\@fields); #  %FLD = abbrev(@fields);          # patched Text::Abbrev
  abbrev(*FLD,@fields);
  yyparse();
  $yyval;
}

1;
