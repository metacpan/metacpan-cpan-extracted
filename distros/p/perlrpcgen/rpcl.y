%{
package RPCLParser;

# $Id: rpcl.y,v 1.6 1997/04/30 21:42:22 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

use perlrpcgen::RPCL;
%}

%token CONST IDENT CONSTANT ENUM STRUCT TYPE UNION SWITCH CASE DEFAULT
%token TYPEDEF PROGRAM VERSION CONST OPAQUE STRING INT UNSIGNED FLOAT
%token DOUBLE BOOL VOID

%%

/* $Id: rpcl.y,v 1.6 1997/04/30 21:42:22 jake Exp $ */

/* Grammar adapted from RFCs 1014 and 1057 */

/* This grammer is for perl-byacc1.8.2 with perl5-byacc-patches-0.5,
 * available at CPAN/authors/id/JAKE/perl5-byacc-patches-0.5.tar.gz
 */

start:			specification
		;

declaration:		type_specifier IDENT
			{ $$ = RPCL::Decl->new($1, $2); }
		|	type_specifier IDENT '[' value ']'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeFixedArr->new($1, $4), $2); }
		|	type_specifier IDENT '<' value '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarArr->new($1, $4, $2), $2); }
		|	type_specifier IDENT '<' '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarArr->new($1, undef, $2), $2); }
		|	OPAQUE IDENT '[' value ']'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeFixedOpq->new($4), $2); }
		|	OPAQUE IDENT '<' value '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarOpq->new($4, $2), $2); }
		|	OPAQUE IDENT '<' '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarOpq->new(undef, $2), $2); }
		|	STRING IDENT '<' value '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarStr->new($4, $2), $2); }
		|	STRING IDENT '<' '>'
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVarStr->new(undef, $2), $2); }
		|	type_specifier '*' IDENT
			{ $$ = RPCL::Decl->new
			  (RPCL::TypePtr->new($1), $3); }
		|	VOID
			{ $$ = RPCL::Decl->new
			  (RPCL::TypeVoid->new(), undef); }
		;

value:			CONSTANT
			{ $$ = RPCL::Constant->new($1); }
		|	IDENT
			{ $$ = RPCL::NamedConstant->new($1); }
		;

type_specifier:		INT
			{ $$ = RPCL::TypeInt->new(); }
		|	UNSIGNED INT
			{ $$ = RPCL::TypeUInt->new(); }
		|	UNSIGNED
			{ $$ = RPCL::TypeUInt->new(); }
		|	FLOAT
			{ $$ = RPCL::TypeFloat->new(); }
		|	DOUBLE
			{ $$ = RPCL::TypeDouble->new(); }
		|	BOOL
			{ $$ = RPCL::TypeBool->new(); }
		|	VOID
			{ $$ = RPCL::TypeVoid->new(); }
		|	enum_type_spec
		|	struct_type_spec
		|	union_type_spec
		|	IDENT
			{ $$ = RPCL::TypeName->new($1); }
		|	STRUCT IDENT
			{ $$ = RPCL::TypeName->new($2); }
		|	UNION IDENT
			{ $$ = RPCL::TypeName->new($2); }
		|	ENUM IDENT
			{ $$ = RPCL::TypeName->new($2); }
		;

enum_type_spec:		ENUM enum_body
			{ $$ = RPCL::EnumDef->new(&gensym('enum'), $2); }
		;

enum_body:		'{' enum_list '}'
			{ $$ = $2; }
		;

enum_list:		IDENT '=' value
			{ $$ = [ RPCL::EnumVal->new($1, $3) ]; }
		|	enum_list ',' IDENT '=' value
			{ $$ = $1; push(@{$$}, RPCL::EnumVal->new($3, $5)); }
		;

struct_type_spec:	STRUCT struct_body
			{ $$ = RPCL::StructDef->new(&gensym('struct'), $2); }
		;

struct_body:		'{' struct_list '}'
			{ $$ = $2; }
		;

struct_list:		declaration ';'
			{ $$ = [ $1 ]; }
		|	struct_list declaration ';'
			{ $$ = $1; push(@{$$}, $2); }
		;

union_type_spec:	UNION union_body
			{ $$ = RPCL::UnionDef
			  (&gensym('union'), $2->[0], $2->[1]); }
		;

union_body:		SWITCH '(' declaration ')' '{' switch_body '}'
			{ $$ = [ $3, $6 ]; }
		;

switch_body:		case_list
			{ $$ = [ $1 ]; }
		|	case_list default
			{ $$ = $1; push(@{$$}, $2); }
		;

case_list:		CASE value ':' declaration ';'
			{ $$ = [ RPCL::Case->new($2, $4) ] }
		|	case_list CASE value ':' declaration ';'
			{ $$ = $1; push(@{$$}, RPCL::Case->new($3, $5)); }
		;

default:		DEFAULT ':' declaration ';'
			{ $$ = RPCL::CaseDefault->new($3); }
		;

constant_def:		CONST IDENT '=' CONSTANT ';'
			{ $$ = RPCL::ConstDef->new($2, $4);
			  $main::consts{$2} = $4; }
		;

type_def:		TYPEDEF declaration ';'
			{ $$ = RPCL::TypedefDef->new($2->ident, $2->type);
			  $main::types{$2->ident} = $$; }
		|	ENUM IDENT enum_body ';'
			{ $$ = RPCL::EnumDef->new($2, $3);
			  $main::types{$2} = $$; }
		|	STRUCT IDENT struct_body ';'
			{ $$ = RPCL::StructDef->new($2, $3);
			  $main::types{$2} = $$; }
		|	STRUCT '*' IDENT struct_body ';'
			{ $$ = RPCL::StructPDef->new($3, $4);
			  $main::types{$3} = $$; }
		|	UNION IDENT union_body ';'
			{ $$ = RPCL::UnionDef->new($2, $3->[0], $3->[1]);
			  $main::types{$2} = $$; }
		;

program_def:		PROGRAM IDENT '{' version_list '}' '=' CONSTANT ';'
			{ $$ = RPCL::ProgramDef->new($2, $4, $7); }
		;

version_list:		version_def
			{ $$ = [ $1 ]; }
		|	version_list version_def
			{ $$ = $1; push(@{$$}, $2); }
		;

version_def:		VERSION IDENT '{' procedure_list '}' '=' CONSTANT ';'
			{ $$ = RPCL::Version->new($2, $4, $7); }
		;

procedure_list:		procedure_def
			{ $$ = [ $1 ]; }
		|	procedure_list procedure_def
			{ $$ = $1; push(@{$$}, $2); }
		;

procedure_def:		type_specifier IDENT '(' type_specifier ')'
			'=' CONSTANT ';'
			{ $$ = RPCL::Procedure->new($1, $2, $4, $7); }
		;

definition:		type_def
		|	constant_def
		|	program_def
		;

specification:		definition
			{ $$ = [ $1 ]; }
		|	specification definition
			{ $$ = $1; push(@{$$}, $2); }
		;

%%

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
