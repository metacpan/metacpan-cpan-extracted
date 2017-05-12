%{
#                              -*- Mode: Perl -*- 
# waisquery.y -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Sep 13 15:54:19 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:28 1998
# Language        : CPerl
# Update Count    : 129
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

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
%}
%token    WORD
%token    PHONIX SOUNDEX ASSIGN FLOAT
%left     OR
%left     AND
%left     NOT
%nonassoc PROX_ORDERED PROX_UNORDERED PROX_ATLEAST
%%
query           : expression
                ;

or              : %prec OR 
                | OR 
                ;

expression      : term
                | expression or term { $$ = $$->merge($3); }
                ;

term            : factor
                | term AND factor {$$ = new WAIT::Query::and $1, $3;}
                | term NOT factor {$$ = new WAIT::Query::not $1, $3;}
                ;

factor          : unit
                | unit PROX_ORDERED unit
                | unit PROX_UNORDERED unit
                | PROX_ATLEAST unit
                ;

unit            : w_unit 
                | '(' expression ')' { $$ = $2; }
                | WORD '=' {enter($1);} '(' s_expression ')'
                  {leave($1); $$ = $5; }
                | WORD '=' {enter($1);}  w_unit {leave($1); $$ = $4; }
                | WORD {enter($1);} '<' WORD
                       {$$ = intervall(undef, $4); leave($1);}
                | WORD {enter($1);} '>' WORD
                       {$$ = intervall($4, undef); leave($1);}
                | WORD {enter($1);} '[' WORD ',' WORD ']'
                       {$$ = intervall($4, $6); leave($1);}
                ;
                ;
phonsound       : PHONIX  
                | SOUNDEX 
                ;
s_expression    : s_term 
                | s_expression or s_term { $$ = $$->merge($3); }
                ;

s_term          : s_factor 
                | s_term AND s_factor {$$ = new WAIT::Query::and $1, $3;}
                | s_term NOT s_factor {$$ = new WAIT::Query::not $1, $3;}
                ;

s_factor        : s_unit
                | s_unit PROX_ORDERED s_unit
                | s_unit PROX_UNORDERED s_unit
                | PROX_ATLEAST s_unit
                ;

s_unit          : w_unit
                | '(' s_expression ')' { $$ = $2; }
                ;
a_unit          : WORD { $$ = plain($1); }
                | phonsound WORD { $$ = plain($2); }
                ;
w_unit          : a_unit 
                | a_unit ASSIGN FLOAT
%%
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
