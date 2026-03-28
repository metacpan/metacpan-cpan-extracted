/* A Bison parser, made by GNU Bison 3.7.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_SYCK_GRAM_H_INCLUDED
# define YY_SYCK_GRAM_H_INCLUDED
/* Debug traces.  */
#ifndef SYCKDEBUG
# if defined YYDEBUG
#if YYDEBUG
#   define SYCKDEBUG 1
#  else
#   define SYCKDEBUG 0
#  endif
# else /* ! defined YYDEBUG */
#  define SYCKDEBUG 0
# endif /* ! defined YYDEBUG */
#endif  /* ! defined SYCKDEBUG */
#if SYCKDEBUG
extern int syckdebug;
#endif

/* Token kinds.  */
#ifndef SYCKTOKENTYPE
# define SYCKTOKENTYPE
  enum sycktokentype
  {
    SYCKEMPTY = -2,
    SYCKEOF = 0,                   /* "end of file"  */
    SYCKerror = 256,               /* error  */
    SYCKUNDEF = 257,               /* "invalid token"  */
    YAML_ANCHOR = 258,             /* YAML_ANCHOR  */
    YAML_ALIAS = 259,              /* YAML_ALIAS  */
    YAML_TRANSFER = 260,           /* YAML_TRANSFER  */
    YAML_TAGURI = 261,             /* YAML_TAGURI  */
    YAML_ITRANSFER = 262,          /* YAML_ITRANSFER  */
    YAML_WORD = 263,               /* YAML_WORD  */
    YAML_PLAIN = 264,              /* YAML_PLAIN  */
    YAML_BLOCK = 265,              /* YAML_BLOCK  */
    YAML_DOCSEP = 266,             /* YAML_DOCSEP  */
    YAML_IOPEN = 267,              /* YAML_IOPEN  */
    YAML_INDENT = 268,             /* YAML_INDENT  */
    YAML_IEND = 269                /* YAML_IEND  */
  };
  typedef enum sycktokentype sycktoken_kind_t;
#endif

/* Value type.  */
#if ! defined SYCKSTYPE && ! defined SYCKSTYPE_IS_DECLARED
union SYCKSTYPE
{
#line 37 "gram.y"

    SYMID nodeId;
    SyckNode *nodeData;
    char *name;

#line 92 "gram.h"

};
typedef union SYCKSTYPE SYCKSTYPE;
# define SYCKSTYPE_IS_TRIVIAL 1
# define SYCKSTYPE_IS_DECLARED 1
#endif



int syckparse (void *parser);
/* "%code provides" blocks.  */
#line 43 "gram.y"

    int sycklex( SYCKSTYPE *sycklval, SyckParser *parser );

#line 108 "gram.h"

#endif /* !YY_SYCK_GRAM_H_INCLUDED  */
