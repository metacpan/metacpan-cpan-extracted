/* A Bison parser, made by GNU Bison 3.7.4.  */

/* Bison implementation for Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30704

/* Bison version string.  */
#define YYBISON_VERSION "3.7.4"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 2

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Substitute the type names.  */
#define YYSTYPE         SYCKSTYPE
/* Substitute the variable and function names.  */
#define yyparse         syckparse
#define yylex           sycklex
#define yyerror         syckerror
#define yydebug         syckdebug
#define yynerrs         sycknerrs

/* First part of user prologue.  */
#line 1 "gram.y"


#include "syck.h"

void apply_seq_in_map( SyckParser *parser, SyckNode *n );

/* Bison 3.x calls yyerror(parser, msg) with 2 args due to %parse-param.
 * Redirect to a wrapper that drops the parser arg and calls the real function. */
static void syck_gram_error(void *parser_arg, const char *msg) {
    void syckerror(char *);
    (void)parser_arg;
    syckerror((char *)msg);
}
#undef yyerror
#define yyerror syck_gram_error

/* sycklex declared after YYSTYPE is defined, via %code provides below */

#define NULL_NODE(parser, node) \
        SyckNode *node = syck_new_str( "", scalar_plain ); \
        if ( ((SyckParser *)parser)->taguri_expansion == 1 ) \
        { \
            node->type_id = syck_taguri( YAML_DOMAIN, "null", 4 ); \
        } \
        else \
        { \
            node->type_id = syck_strndup( "null", 4 ); \
        }


#line 108 "gram.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "gram.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_YAML_ANCHOR = 3,                /* YAML_ANCHOR  */
  YYSYMBOL_YAML_ALIAS = 4,                 /* YAML_ALIAS  */
  YYSYMBOL_YAML_TRANSFER = 5,              /* YAML_TRANSFER  */
  YYSYMBOL_YAML_TAGURI = 6,                /* YAML_TAGURI  */
  YYSYMBOL_YAML_ITRANSFER = 7,             /* YAML_ITRANSFER  */
  YYSYMBOL_YAML_WORD = 8,                  /* YAML_WORD  */
  YYSYMBOL_YAML_PLAIN = 9,                 /* YAML_PLAIN  */
  YYSYMBOL_YAML_BLOCK = 10,                /* YAML_BLOCK  */
  YYSYMBOL_YAML_DOCSEP = 11,               /* YAML_DOCSEP  */
  YYSYMBOL_YAML_IOPEN = 12,                /* YAML_IOPEN  */
  YYSYMBOL_YAML_INDENT = 13,               /* YAML_INDENT  */
  YYSYMBOL_YAML_IEND = 14,                 /* YAML_IEND  */
  YYSYMBOL_15_ = 15,                       /* '-'  */
  YYSYMBOL_16_ = 16,                       /* '['  */
  YYSYMBOL_17_ = 17,                       /* ']'  */
  YYSYMBOL_18_ = 18,                       /* ','  */
  YYSYMBOL_19_ = 19,                       /* '?'  */
  YYSYMBOL_20_ = 20,                       /* ':'  */
  YYSYMBOL_21_ = 21,                       /* '{'  */
  YYSYMBOL_22_ = 22,                       /* '}'  */
  YYSYMBOL_YYACCEPT = 23,                  /* $accept  */
  YYSYMBOL_doc = 24,                       /* doc  */
  YYSYMBOL_atom = 25,                      /* atom  */
  YYSYMBOL_ind_rep = 26,                   /* ind_rep  */
  YYSYMBOL_atom_or_empty = 27,             /* atom_or_empty  */
  YYSYMBOL_empty = 28,                     /* empty  */
  YYSYMBOL_indent_open = 29,               /* indent_open  */
  YYSYMBOL_indent_end = 30,                /* indent_end  */
  YYSYMBOL_indent_sep = 31,                /* indent_sep  */
  YYSYMBOL_indent_flex_end = 32,           /* indent_flex_end  */
  YYSYMBOL_word_rep = 33,                  /* word_rep  */
  YYSYMBOL_struct_rep = 34,                /* struct_rep  */
  YYSYMBOL_implicit_seq = 35,              /* implicit_seq  */
  YYSYMBOL_basic_seq = 36,                 /* basic_seq  */
  YYSYMBOL_top_imp_seq = 37,               /* top_imp_seq  */
  YYSYMBOL_in_implicit_seq = 38,           /* in_implicit_seq  */
  YYSYMBOL_inline_seq = 39,                /* inline_seq  */
  YYSYMBOL_in_inline_seq = 40,             /* in_inline_seq  */
  YYSYMBOL_inline_seq_atom = 41,           /* inline_seq_atom  */
  YYSYMBOL_implicit_map = 42,              /* implicit_map  */
  YYSYMBOL_top_imp_map = 43,               /* top_imp_map  */
  YYSYMBOL_complex_key = 44,               /* complex_key  */
  YYSYMBOL_complex_value = 45,             /* complex_value  */
  YYSYMBOL_complex_mapping = 46,           /* complex_mapping  */
  YYSYMBOL_in_implicit_map = 47,           /* in_implicit_map  */
  YYSYMBOL_basic_mapping = 48,             /* basic_mapping  */
  YYSYMBOL_inline_map = 49,                /* inline_map  */
  YYSYMBOL_in_inline_map = 50,             /* in_inline_map  */
  YYSYMBOL_inline_map_atom = 51            /* inline_map_atom  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && ! defined __ICC && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                            \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined SYCKSTYPE_IS_TRIVIAL && SYCKSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  49
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   388

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  23
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  29
/* YYNRULES -- Number of rules.  */
#define YYNRULES  80
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  126

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   269


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,    18,    15,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,    20,     2,
       2,     2,     2,    19,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    16,     2,    17,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    21,     2,    22,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14
};

#if SYCKDEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,    62,    62,    66,    71,    76,    77,    80,    81,    86,
      91,   100,   108,   115,   116,   119,   124,   128,   136,   141,
     146,   158,   159,   163,   167,   171,   172,   176,   181,   186,
     194,   198,   206,   219,   220,   227,   228,   229,   230,   231,
     235,   239,   246,   253,   258,   263,   268,   273,   277,   284,
     288,   293,   300,   304,   311,   315,   323,   324,   328,   333,
     341,   346,   351,   356,   361,   365,   372,   373,   380,   384,
     393,   394,   406,   414,   421,   430,   434,   441,   442,   452,
     459
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if SYCKDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "YAML_ANCHOR",
  "YAML_ALIAS", "YAML_TRANSFER", "YAML_TAGURI", "YAML_ITRANSFER",
  "YAML_WORD", "YAML_PLAIN", "YAML_BLOCK", "YAML_DOCSEP", "YAML_IOPEN",
  "YAML_INDENT", "YAML_IEND", "'-'", "'['", "']'", "','", "'?'", "':'",
  "'{'", "'}'", "$accept", "doc", "atom", "ind_rep", "atom_or_empty",
  "empty", "indent_open", "indent_end", "indent_sep", "indent_flex_end",
  "word_rep", "struct_rep", "implicit_seq", "basic_seq", "top_imp_seq",
  "in_implicit_seq", "inline_seq", "in_inline_seq", "inline_seq_atom",
  "implicit_map", "top_imp_map", "complex_key", "complex_value",
  "complex_mapping", "in_implicit_map", "basic_mapping", "inline_map",
  "in_inline_map", "inline_map_atom", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_int16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,    45,    91,    93,    44,    63,
      58,   123,   125
};
#endif

#define YYPACT_NINF (-92)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     255,   331,   -92,   331,   331,   331,   -92,   -92,   -92,   350,
     -92,   274,   190,     9,   -92,   -92,   210,   -92,   -92,   -92,
     -92,   -92,   -92,   -92,   -92,   -92,   -92,   -92,   -92,   -92,
     -92,   350,   350,   350,   350,   -92,   -92,   -92,   236,   -92,
      -4,    11,   -92,   -92,   -92,    -4,   -92,    23,   -92,   -92,
     293,   293,   293,   -92,   350,   331,    34,    34,   -92,     4,
      41,     4,    16,   -92,    41,   -92,   -92,   -92,   -92,   312,
     312,   312,     4,   350,   -92,   331,   331,   -92,   -92,   369,
     -92,   -92,   369,   -92,   -92,   369,   -92,   -92,   -92,    26,
     -92,    34,   -92,   -92,   -92,   -92,   -92,    37,   -92,   350,
     -92,   369,   -92,   -92,   -92,   -92,   108,   108,   108,   108,
     171,   -92,    26,    26,    26,    26,    26,    26,   -92,   -92,
     -92,   -92,   -92,   -92,   -92,    34
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       4,     0,    31,     0,     0,     0,    32,    33,    35,    16,
      21,     0,     0,     0,     2,     6,     0,     5,     7,    36,
      37,    38,    39,    10,    30,     8,    27,     9,    28,    11,
      29,    16,    16,    16,    16,    13,     3,    14,    16,    53,
      56,     0,    54,    57,    76,    79,    80,     0,    77,     1,
       0,     0,     0,    22,    16,     0,     0,    66,    49,     0,
       0,     0,     0,    70,     0,    20,    18,    19,    17,    16,
      16,    16,     0,    16,    52,     0,     0,    75,    24,     0,
      48,    65,     0,    44,    61,     0,    46,    63,    42,     0,
      25,     0,    12,    34,    23,    40,    41,    51,    58,    16,
      59,    73,    15,    74,    55,    78,     0,     0,     0,     0,
       0,    66,    47,    64,    43,    60,    45,    62,    67,    26,
      50,    68,    69,    71,    72,     0
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -92,   -92,     1,   118,   -46,   -12,    56,   -26,   121,   -51,
      -1,   -92,   -92,   -91,   -27,   -68,   -92,   -92,   -14,   -92,
      22,   -92,   -92,   -39,   -19,    -5,   -92,   -92,    -9
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,    13,    35,    15,    36,    37,    16,    95,    91,    93,
      17,    18,    19,    58,    59,    60,    20,    41,    42,    21,
      61,    62,   122,    63,    64,    43,    22,    47,    48
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      24,    14,    26,    28,    30,    92,   120,    46,    88,    49,
     123,   112,    40,    45,   114,    57,    73,   116,    94,    65,
      66,    67,    68,    80,    83,    86,    72,   103,    74,    75,
      24,    26,    28,    30,    96,    98,    99,    57,   100,    78,
     119,    76,    80,    83,    86,    77,   102,    78,    90,    24,
      26,    28,    54,   121,    78,    94,    89,    65,    66,    67,
     113,   104,   124,   115,     0,    38,   117,   105,    24,    26,
      28,    46,    81,    84,    87,     0,    40,    45,   111,     0,
       0,   111,     0,     0,   111,     0,     0,    38,    38,    38,
      38,    81,    84,    87,    38,     0,     0,     0,     0,     0,
     111,     0,     0,     0,     0,    24,    26,    28,    30,   125,
      38,   106,     2,   107,   108,   109,     6,     7,     0,    23,
      10,    25,    27,    29,     0,    38,    38,    38,     0,    38,
       0,     0,     0,     0,    56,   110,     0,     0,   110,     0,
       0,   110,     0,     0,     0,     0,     0,     0,     0,    23,
      25,    27,    29,     0,     0,    38,    56,   110,     0,     0,
       0,     0,   110,   110,   110,   110,   110,     0,    23,    25,
      27,    79,    82,    85,   106,     2,   107,   108,   109,     6,
       7,    97,     0,    10,    53,   101,     0,    23,    25,    27,
      79,    82,    85,     1,     2,     3,     4,     5,     6,     7,
       8,     0,    10,     0,     0,     0,    11,     0,     0,     0,
     118,    12,    44,    50,     2,    51,    52,     5,     6,     7,
       8,     0,    10,    53,     0,    54,    11,     0,     0,    55,
       0,    12,     0,    97,   101,    97,   101,    97,   101,    69,
       2,    70,    71,    34,     6,     7,     8,     0,    10,    53,
       0,    54,    11,     0,     0,    55,     0,    12,     1,     2,
       3,     4,     5,     6,     7,     8,     9,    10,     0,     0,
       0,    11,     0,     0,     0,     0,    12,     1,     2,     3,
       4,     5,     6,     7,     8,     0,    10,     0,     0,     0,
      11,    39,     0,     0,     0,    12,    50,     2,    51,    52,
       5,     6,     7,     8,     0,    10,    78,     0,     0,    11,
       0,     0,     0,     0,    12,    69,     2,    70,    71,    34,
       6,     7,     8,     0,    10,    78,     0,     0,    11,     0,
       0,     0,     0,    12,     1,     2,     3,     4,     5,     6,
       7,     8,     0,    10,     0,     0,     0,    11,     0,     0,
       0,     0,    12,    31,     2,    32,    33,    34,     6,     7,
       8,     0,    10,     0,     0,     0,    11,     0,     0,     0,
       0,    12,   106,     2,   107,   108,   109,     6,     7,     0,
       0,    10,     0,     0,    54,     0,     0,     0,    55
};

static const yytype_int8 yycheck[] =
{
       1,     0,     3,     4,     5,    56,    97,    12,    54,     0,
     101,    79,    11,    12,    82,    16,    20,    85,    14,    31,
      32,    33,    34,    50,    51,    52,    38,    73,    17,    18,
      31,    32,    33,    34,    60,    61,    20,    38,    64,    13,
      91,    18,    69,    70,    71,    22,    72,    13,    14,    50,
      51,    52,    15,    99,    13,    14,    55,    69,    70,    71,
      79,    75,   101,    82,    -1,     9,    85,    76,    69,    70,
      71,    76,    50,    51,    52,    -1,    75,    76,    79,    -1,
      -1,    82,    -1,    -1,    85,    -1,    -1,    31,    32,    33,
      34,    69,    70,    71,    38,    -1,    -1,    -1,    -1,    -1,
     101,    -1,    -1,    -1,    -1,   106,   107,   108,   109,   110,
      54,     3,     4,     5,     6,     7,     8,     9,    -1,     1,
      12,     3,     4,     5,    -1,    69,    70,    71,    -1,    73,
      -1,    -1,    -1,    -1,    16,    79,    -1,    -1,    82,    -1,
      -1,    85,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    31,
      32,    33,    34,    -1,    -1,    99,    38,   101,    -1,    -1,
      -1,    -1,   106,   107,   108,   109,   110,    -1,    50,    51,
      52,    50,    51,    52,     3,     4,     5,     6,     7,     8,
       9,    60,    -1,    12,    13,    64,    -1,    69,    70,    71,
      69,    70,    71,     3,     4,     5,     6,     7,     8,     9,
      10,    -1,    12,    -1,    -1,    -1,    16,    -1,    -1,    -1,
      89,    21,    22,     3,     4,     5,     6,     7,     8,     9,
      10,    -1,    12,    13,    -1,    15,    16,    -1,    -1,    19,
      -1,    21,    -1,   112,   113,   114,   115,   116,   117,     3,
       4,     5,     6,     7,     8,     9,    10,    -1,    12,    13,
      -1,    15,    16,    -1,    -1,    19,    -1,    21,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    -1,    -1,
      -1,    16,    -1,    -1,    -1,    -1,    21,     3,     4,     5,
       6,     7,     8,     9,    10,    -1,    12,    -1,    -1,    -1,
      16,    17,    -1,    -1,    -1,    21,     3,     4,     5,     6,
       7,     8,     9,    10,    -1,    12,    13,    -1,    -1,    16,
      -1,    -1,    -1,    -1,    21,     3,     4,     5,     6,     7,
       8,     9,    10,    -1,    12,    13,    -1,    -1,    16,    -1,
      -1,    -1,    -1,    21,     3,     4,     5,     6,     7,     8,
       9,    10,    -1,    12,    -1,    -1,    -1,    16,    -1,    -1,
      -1,    -1,    21,     3,     4,     5,     6,     7,     8,     9,
      10,    -1,    12,    -1,    -1,    -1,    16,    -1,    -1,    -1,
      -1,    21,     3,     4,     5,     6,     7,     8,     9,    -1,
      -1,    12,    -1,    -1,    15,    -1,    -1,    -1,    19
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,     3,     4,     5,     6,     7,     8,     9,    10,    11,
      12,    16,    21,    24,    25,    26,    29,    33,    34,    35,
      39,    42,    49,    26,    33,    26,    33,    26,    33,    26,
      33,     3,     5,     6,     7,    25,    27,    28,    29,    17,
      25,    40,    41,    48,    22,    25,    48,    50,    51,     0,
       3,     5,     6,    13,    15,    19,    26,    33,    36,    37,
      38,    43,    44,    46,    47,    28,    28,    28,    28,     3,
       5,     6,    28,    20,    17,    18,    18,    22,    13,    31,
      37,    43,    31,    37,    43,    31,    37,    43,    27,    25,
      14,    31,    32,    32,    14,    30,    30,    31,    30,    20,
      30,    31,    30,    27,    41,    51,     3,     5,     6,     7,
      29,    33,    38,    47,    38,    47,    38,    47,    31,    32,
      36,    27,    45,    36,    46,    33
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_int8 yyr1[] =
{
       0,    23,    24,    24,    24,    25,    25,    26,    26,    26,
      26,    26,    26,    27,    27,    28,    28,    28,    28,    28,
      28,    29,    29,    30,    31,    32,    32,    33,    33,    33,
      33,    33,    33,    33,    33,    34,    34,    34,    34,    34,
      35,    35,    36,    37,    37,    37,    37,    37,    37,    38,
      38,    38,    39,    39,    40,    40,    41,    41,    42,    42,
      43,    43,    43,    43,    43,    43,    44,    44,    45,    46,
      47,    47,    47,    47,    48,    49,    49,    50,    50,    51,
      51
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     2,     0,     1,     1,     1,     2,     2,
       2,     2,     3,     1,     1,     3,     0,     2,     2,     2,
       2,     1,     2,     1,     1,     1,     2,     2,     2,     2,
       2,     1,     1,     1,     3,     1,     1,     1,     1,     1,
       3,     3,     2,     3,     2,     3,     2,     3,     2,     1,
       3,     2,     3,     2,     1,     3,     1,     1,     3,     3,
       3,     2,     3,     2,     3,     2,     1,     3,     1,     3,
       1,     3,     3,     2,     3,     3,     2,     1,     3,     1,
       1
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = SYCKEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == SYCKEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (parser, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use SYCKerror or SYCKUNDEF. */
#define YYERRCODE SYCKUNDEF


/* Enable debugging if requested.  */
#if SYCKDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)

/* This macro is provided for backward compatibility. */
# ifndef YY_LOCATION_PRINT
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif


# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, parser); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, void *parser)
{
  FILE *yyoutput = yyo;
  YYUSE (yyoutput);
  YYUSE (parser);
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yykind < YYNTOKENS)
    YYPRINT (yyo, yytoknum[yykind], *yyvaluep);
# endif
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, void *parser)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, parser);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule, void *parser)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)], parser);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, parser); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !SYCKDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !SYCKDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, void *parser)
{
  YYUSE (yyvaluep);
  YYUSE (parser);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}






/*----------.
| yyparse.  |
`----------*/

int
yyparse (void *parser)
{
/* Lookahead token kind.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs = 0;

    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = SYCKEMPTY; /* Cause a token to be read.  */
  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    goto yyexhaustedlab;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          goto yyexhaustedlab;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == SYCKEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex (&yylval, parser);
    }

  if (yychar <= SYCKEOF)
    {
      yychar = SYCKEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == SYCKerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = SYCKUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = SYCKEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* doc: atom  */
#line 63 "gram.y"
        {
           ((SyckParser *)parser)->root = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) );
        }
#line 1289 "gram.c"
    break;

  case 3: /* doc: YAML_DOCSEP atom_or_empty  */
#line 67 "gram.y"
        {
           ((SyckParser *)parser)->root = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) );
        }
#line 1297 "gram.c"
    break;

  case 4: /* doc: %empty  */
#line 71 "gram.y"
        {
           ((SyckParser *)parser)->eof = 1;
        }
#line 1305 "gram.c"
    break;

  case 8: /* ind_rep: YAML_TRANSFER ind_rep  */
#line 82 "gram.y"
        {
            syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
            (yyval.nodeData) = (yyvsp[0].nodeData);
        }
#line 1314 "gram.c"
    break;

  case 9: /* ind_rep: YAML_TAGURI ind_rep  */
#line 87 "gram.y"
        {
            syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), 0 );
            (yyval.nodeData) = (yyvsp[0].nodeData);
        }
#line 1323 "gram.c"
    break;

  case 10: /* ind_rep: YAML_ANCHOR ind_rep  */
#line 92 "gram.y"
        {
           /*
            * _Anchors_: The language binding must keep a separate symbol table
            * for anchors.  The actual ID in the symbol table is returned to the
            * higher nodes, though.
            */
           (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-1].name), (yyvsp[0].nodeData) );
        }
#line 1336 "gram.c"
    break;

  case 11: /* ind_rep: YAML_ITRANSFER ind_rep  */
#line 101 "gram.y"
        {
           if ( ((SyckParser *)parser)->implicit_typing == 1 )
           {
              try_tag_implicit( (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
           }
           (yyval.nodeData) = (yyvsp[0].nodeData);
        }
#line 1348 "gram.c"
    break;

  case 12: /* ind_rep: indent_open ind_rep indent_flex_end  */
#line 109 "gram.y"
        {
           (yyval.nodeData) = (yyvsp[-1].nodeData);
        }
#line 1356 "gram.c"
    break;

  case 15: /* empty: indent_open empty indent_end  */
#line 120 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1364 "gram.c"
    break;

  case 16: /* empty: %empty  */
#line 124 "gram.y"
        {
                    NULL_NODE( parser, n );
                    (yyval.nodeData) = n;
                }
#line 1373 "gram.c"
    break;

  case 17: /* empty: YAML_ITRANSFER empty  */
#line 129 "gram.y"
        {
                   if ( ((SyckParser *)parser)->implicit_typing == 1 )
                   {
                      try_tag_implicit( (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                   }
                   (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1385 "gram.c"
    break;

  case 18: /* empty: YAML_TRANSFER empty  */
#line 137 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1394 "gram.c"
    break;

  case 19: /* empty: YAML_TAGURI empty  */
#line 142 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1403 "gram.c"
    break;

  case 20: /* empty: YAML_ANCHOR empty  */
#line 147 "gram.y"
        {
                   /*
                    * _Anchors_: The language binding must keep a separate symbol table
                    * for anchors.  The actual ID in the symbol table is returned to the
                    * higher nodes, though.
                    */
                   (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-1].name), (yyvsp[0].nodeData) );
                }
#line 1416 "gram.c"
    break;

  case 27: /* word_rep: YAML_TRANSFER word_rep  */
#line 177 "gram.y"
        {
               syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
               (yyval.nodeData) = (yyvsp[0].nodeData);
            }
#line 1425 "gram.c"
    break;

  case 28: /* word_rep: YAML_TAGURI word_rep  */
#line 182 "gram.y"
        {
               syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), 0 );
               (yyval.nodeData) = (yyvsp[0].nodeData);
            }
#line 1434 "gram.c"
    break;

  case 29: /* word_rep: YAML_ITRANSFER word_rep  */
#line 187 "gram.y"
        {
               if ( ((SyckParser *)parser)->implicit_typing == 1 )
               {
                  try_tag_implicit( (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
               }
               (yyval.nodeData) = (yyvsp[0].nodeData);
            }
#line 1446 "gram.c"
    break;

  case 30: /* word_rep: YAML_ANCHOR word_rep  */
#line 195 "gram.y"
        {
               (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-1].name), (yyvsp[0].nodeData) );
            }
#line 1454 "gram.c"
    break;

  case 31: /* word_rep: YAML_ALIAS  */
#line 199 "gram.y"
        {
               /*
                * _Aliases_: The anchor symbol table is scanned for the anchor name.
                * The anchor's ID in the language's symbol table is returned.
                */
               (yyval.nodeData) = syck_hdlr_get_anchor( (SyckParser *)parser, (yyvsp[0].name) );
            }
#line 1466 "gram.c"
    break;

  case 32: /* word_rep: YAML_WORD  */
#line 207 "gram.y"
        {
               SyckNode *n = (yyvsp[0].nodeData);
               if ( ((SyckParser *)parser)->taguri_expansion == 1 )
               {
                   n->type_id = syck_taguri( YAML_DOMAIN, "str", 3 );
               }
               else
               {
                   n->type_id = syck_strndup( "str", 3 );
               }
               (yyval.nodeData) = n;
            }
#line 1483 "gram.c"
    break;

  case 34: /* word_rep: indent_open word_rep indent_flex_end  */
#line 221 "gram.y"
        {
               (yyval.nodeData) = (yyvsp[-1].nodeData);
            }
#line 1491 "gram.c"
    break;

  case 40: /* implicit_seq: indent_open top_imp_seq indent_end  */
#line 236 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1499 "gram.c"
    break;

  case 41: /* implicit_seq: indent_open in_implicit_seq indent_end  */
#line 240 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1507 "gram.c"
    break;

  case 42: /* basic_seq: '-' atom_or_empty  */
#line 247 "gram.y"
        {
                    (yyval.nodeId) = syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) );
                }
#line 1515 "gram.c"
    break;

  case 43: /* top_imp_seq: YAML_TRANSFER indent_sep in_implicit_seq  */
#line 254 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-2].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1524 "gram.c"
    break;

  case 44: /* top_imp_seq: YAML_TRANSFER top_imp_seq  */
#line 259 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1533 "gram.c"
    break;

  case 45: /* top_imp_seq: YAML_TAGURI indent_sep in_implicit_seq  */
#line 264 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-2].name), (yyvsp[0].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1542 "gram.c"
    break;

  case 46: /* top_imp_seq: YAML_TAGURI top_imp_seq  */
#line 269 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1551 "gram.c"
    break;

  case 47: /* top_imp_seq: YAML_ANCHOR indent_sep in_implicit_seq  */
#line 274 "gram.y"
        {
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-2].name), (yyvsp[0].nodeData) );
                }
#line 1559 "gram.c"
    break;

  case 48: /* top_imp_seq: YAML_ANCHOR top_imp_seq  */
#line 278 "gram.y"
        {
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-1].name), (yyvsp[0].nodeData) );
                }
#line 1567 "gram.c"
    break;

  case 49: /* in_implicit_seq: basic_seq  */
#line 285 "gram.y"
        {
                    (yyval.nodeData) = syck_new_seq( (yyvsp[0].nodeId) );
                }
#line 1575 "gram.c"
    break;

  case 50: /* in_implicit_seq: in_implicit_seq indent_sep basic_seq  */
#line 289 "gram.y"
        {
                    syck_seq_add( (yyvsp[-2].nodeData), (yyvsp[0].nodeId) );
                    (yyval.nodeData) = (yyvsp[-2].nodeData);
                                }
#line 1584 "gram.c"
    break;

  case 51: /* in_implicit_seq: in_implicit_seq indent_sep  */
#line 294 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                                }
#line 1592 "gram.c"
    break;

  case 52: /* inline_seq: '[' in_inline_seq ']'  */
#line 301 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1600 "gram.c"
    break;

  case 53: /* inline_seq: '[' ']'  */
#line 305 "gram.y"
        {
                    (yyval.nodeData) = syck_alloc_seq();
                }
#line 1608 "gram.c"
    break;

  case 54: /* in_inline_seq: inline_seq_atom  */
#line 312 "gram.y"
        {
                    (yyval.nodeData) = syck_new_seq( syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) ) );
                }
#line 1616 "gram.c"
    break;

  case 55: /* in_inline_seq: in_inline_seq ',' inline_seq_atom  */
#line 316 "gram.y"
        {
                    syck_seq_add( (yyvsp[-2].nodeData), syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) ) );
                    (yyval.nodeData) = (yyvsp[-2].nodeData);
                                }
#line 1625 "gram.c"
    break;

  case 58: /* implicit_map: indent_open top_imp_map indent_end  */
#line 329 "gram.y"
        {
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[-1].nodeData) );
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1634 "gram.c"
    break;

  case 59: /* implicit_map: indent_open in_implicit_map indent_end  */
#line 334 "gram.y"
        {
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[-1].nodeData) );
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1643 "gram.c"
    break;

  case 60: /* top_imp_map: YAML_TRANSFER indent_sep in_implicit_map  */
#line 342 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-2].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1652 "gram.c"
    break;

  case 61: /* top_imp_map: YAML_TRANSFER top_imp_map  */
#line 347 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), ((SyckParser *)parser)->taguri_expansion );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1661 "gram.c"
    break;

  case 62: /* top_imp_map: YAML_TAGURI indent_sep in_implicit_map  */
#line 352 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-2].name), (yyvsp[0].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1670 "gram.c"
    break;

  case 63: /* top_imp_map: YAML_TAGURI top_imp_map  */
#line 357 "gram.y"
        {
                    syck_add_transfer( (yyvsp[-1].name), (yyvsp[0].nodeData), 0 );
                    (yyval.nodeData) = (yyvsp[0].nodeData);
                }
#line 1679 "gram.c"
    break;

  case 64: /* top_imp_map: YAML_ANCHOR indent_sep in_implicit_map  */
#line 362 "gram.y"
        {
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-2].name), (yyvsp[0].nodeData) );
                }
#line 1687 "gram.c"
    break;

  case 65: /* top_imp_map: YAML_ANCHOR top_imp_map  */
#line 366 "gram.y"
        {
                    (yyval.nodeData) = syck_hdlr_add_anchor( (SyckParser *)parser, (yyvsp[-1].name), (yyvsp[0].nodeData) );
                }
#line 1695 "gram.c"
    break;

  case 67: /* complex_key: '?' atom indent_sep  */
#line 374 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1703 "gram.c"
    break;

  case 69: /* complex_mapping: complex_key ':' complex_value  */
#line 385 "gram.y"
        {
                    (yyval.nodeData) = syck_new_map(
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[-2].nodeData) ),
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) ) );
                }
#line 1713 "gram.c"
    break;

  case 71: /* in_implicit_map: in_implicit_map indent_sep basic_seq  */
#line 395 "gram.y"
        {
                    if ( (yyvsp[-2].nodeData)->shortcut == NULL )
                    {
                        (yyvsp[-2].nodeData)->shortcut = syck_new_seq( (yyvsp[0].nodeId) );
                    }
                    else
                    {
                        syck_seq_add( (yyvsp[-2].nodeData)->shortcut, (yyvsp[0].nodeId) );
                    }
                    (yyval.nodeData) = (yyvsp[-2].nodeData);
                }
#line 1729 "gram.c"
    break;

  case 72: /* in_implicit_map: in_implicit_map indent_sep complex_mapping  */
#line 407 "gram.y"
        {
                    apply_seq_in_map( (SyckParser *)parser, (yyvsp[-2].nodeData) );
                    syck_map_update( (yyvsp[-2].nodeData), (yyvsp[0].nodeData) );
                    syck_free_node( (yyvsp[0].nodeData) );
                    (yyvsp[0].nodeData) = NULL;
                    (yyval.nodeData) = (yyvsp[-2].nodeData);
                }
#line 1741 "gram.c"
    break;

  case 73: /* in_implicit_map: in_implicit_map indent_sep  */
#line 415 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1749 "gram.c"
    break;

  case 74: /* basic_mapping: atom ':' atom_or_empty  */
#line 422 "gram.y"
        {
                    (yyval.nodeData) = syck_new_map(
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[-2].nodeData) ),
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) ) );
                }
#line 1759 "gram.c"
    break;

  case 75: /* inline_map: '{' in_inline_map '}'  */
#line 431 "gram.y"
        {
                    (yyval.nodeData) = (yyvsp[-1].nodeData);
                }
#line 1767 "gram.c"
    break;

  case 76: /* inline_map: '{' '}'  */
#line 435 "gram.y"
        {
                    (yyval.nodeData) = syck_alloc_map();
                }
#line 1775 "gram.c"
    break;

  case 78: /* in_inline_map: in_inline_map ',' inline_map_atom  */
#line 443 "gram.y"
        {
                    syck_map_update( (yyvsp[-2].nodeData), (yyvsp[0].nodeData) );
                    syck_free_node( (yyvsp[0].nodeData) );
                    (yyvsp[0].nodeData) = NULL;
                    (yyval.nodeData) = (yyvsp[-2].nodeData);
                                }
#line 1786 "gram.c"
    break;

  case 79: /* inline_map_atom: atom  */
#line 453 "gram.y"
        {
                    NULL_NODE( parser, n );
                    (yyval.nodeData) = syck_new_map(
                        syck_hdlr_add_node( (SyckParser *)parser, (yyvsp[0].nodeData) ),
                        syck_hdlr_add_node( (SyckParser *)parser, n ) );
                }
#line 1797 "gram.c"
    break;


#line 1801 "gram.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == SYCKEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (parser, YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= SYCKEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == SYCKEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, parser);
          yychar = SYCKEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, parser);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;


#if !defined yyoverflow
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (parser, YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturn;
#endif


/*-------------------------------------------------------.
| yyreturn -- parsing is finished, clean up and return.  |
`-------------------------------------------------------*/
yyreturn:
  if (yychar != SYCKEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, parser);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, parser);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 462 "gram.y"


void
apply_seq_in_map( SyckParser *parser, SyckNode *n )
{
    long map_len;
    if ( n->shortcut == NULL )
    {
        return;
    }

    map_len = syck_map_count( n );
    syck_map_assign( n, map_value, map_len - 1,
        syck_hdlr_add_node( parser, n->shortcut ) );

    n->shortcut = NULL;
}
