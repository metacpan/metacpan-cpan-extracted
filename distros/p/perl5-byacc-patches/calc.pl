#!/usr/bin/perl

# $Id: calc.pl,v 1.2 1998/04/29 06:34:46 jake Exp $

# Really trivial calculator.

use CalcParser;
use Fstream;

$s = Fstream->new(\*STDIN, 'STDIN');
$p = CalcParser->new(\&CalcParser::yylex, \&CalcParser::yyerror, 0);

$p->yyparse($s);
