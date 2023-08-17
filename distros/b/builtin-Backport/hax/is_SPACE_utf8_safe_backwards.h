/* This file stolen from the generated regcharclass.h from Perl v5.36
 */

#ifndef inRANGE_helper_
/* These parts stolen from handy.h */
#  define ASSERT_NOT_PTR(x) (x)

#  define withinCOUNT_KNOWN_VALID_(c, l, n)                                   \
      ((((WIDEST_UTYPE) (c)) - ASSERT_NOT_PTR(l))                             \
                                     <= ((WIDEST_UTYPE) ASSERT_NOT_PTR(n)))

#  define inRANGE_helper_(cast, c, l, u)                                      \
                      withinCOUNT_KNOWN_VALID_(((cast) (c)), (l), ((u) - (l)))
#endif

#if 'A' == 65 /* ASCII/Latin1 */
/*
	SPACE: Backwards \p{XPerlSpace}

	\p{XPerlSpace}
*/
/*** GENERATED CODE ***/
#define is_SPACE_utf8_safe_backwards(s,e)                                   \
( ((s) - (e) > 2) ?                                                         \
    ( ( inRANGE_helper_(U8, *((const U8*)s - 1), '\t', '\r') || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( 0x80 == *((const U8*)s - 1) ) ?                                     \
	( ( 0x80 == *((const U8*)s - 2) ) ?                                 \
	    ( ( inRANGE_helper_(U8, *((const U8*)s - 3), 0xE2, 0xE3) ) ? 3 : 0 )\
	: ( ( 0x9A == *((const U8*)s - 2) ) && ( 0xE1 == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( inRANGE_helper_(U8, *((const U8*)s - 1), 0x81, 0x84) || inRANGE_helper_(U8, *((const U8*)s - 1), 0x86, 0x8A) || inRANGE_helper_(U8, *((const U8*)s - 1), 0xA8, 0xA9) || 0xAF == *((const U8*)s - 1) ) ?\
	( ( ( 0x80 == *((const U8*)s - 2) ) && ( 0xE2 == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( 0x85 == *((const U8*)s - 1) ) ?                                     \
	( ( 0x80 == *((const U8*)s - 2) ) ?                                 \
	    ( ( 0xE2 == *((const U8*)s - 3) ) ? 3 : 0 )                     \
	: ( 0xC2 == *((const U8*)s - 2) ) ? 2 : 0 )                         \
    : ( 0x9F == *((const U8*)s - 1) ) ?                                     \
	( ( ( 0x81 == *((const U8*)s - 2) ) && ( 0xE2 == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( ( 0xA0 == *((const U8*)s - 1) ) && ( 0xC2 == *((const U8*)s - 2) ) ) ? 2 : 0 )\
: ((s) - (e) > 1) ?                                                         \
    ( ( inRANGE_helper_(U8, *((const U8*)s - 1), '\t', '\r') || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( ( 0x85 == *((const U8*)s - 1) || 0xA0 == *((const U8*)s - 1) ) && ( 0xC2 == *((const U8*)s - 2) ) ) ? 2 : 0 )\
: ((s) - (e) > 0) ?                                                         \
    ( inRANGE_helper_(U8, *((const U8*)s - 1), '\t', '\r') || ' ' == *((const U8*)s - 1) )\
: 0 )

#endif	/* ASCII/Latin1 */

#if 'A' == 193 /* EBCDIC 1047 */ \
     && '\\' == 224 && '[' == 173 && ']' == 189 && '{' == 192 && '}' == 208 \
     && '^' == 95 && '~' == 161 && '!' == 90 && '#' == 123 && '|' == 79 \
     && '$' == 91 && '@' == 124 && '`' == 121 && '\n' == 21
/*
	SPACE: Backwards \p{XPerlSpace}

	\p{XPerlSpace}
*/
/*** GENERATED CODE ***/
#define is_SPACE_utf8_safe_backwards(s,e)                                   \
( ((s) - (e) > 2) ?                                                         \
    ( ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || '\n' == *((const U8*)s - 1) || 0x25 == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( 0x41 == *((const U8*)s - 1) ) ?                                     \
	( ( 0x41 == *((const U8*)s - 2) ) ?                                 \
	    ( ( ( *((const U8*)s - 3) & 0xFB ) == 0xCA ) ? 3 : 0 )          \
	: ( 0x63 == *((const U8*)s - 2) ) ?                                 \
	    ( ( 0xBC == *((const U8*)s - 3) ) ? 3 : 0 )                     \
	: ( 0x80 == *((const U8*)s - 2) ) ? 2 : 0 )                         \
    : ( inRANGE_helper_(U8, *((const U8*)s - 1), 0x42, 0x48) || 0x51 == *((const U8*)s - 1) ) ?\
	( ( ( 0x41 == *((const U8*)s - 2) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( inRANGE_helper_(U8, *((const U8*)s - 1), 0x49, 0x4A) ) ?            \
	( ( ( inRANGE_helper_(U8, *((const U8*)s - 2), 0x41, 0x42) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( 0x56 == *((const U8*)s - 1) ) ?                                     \
	( ( ( 0x42 == *((const U8*)s - 2) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( ( ( 0x73 == *((const U8*)s - 1) ) && ( 0x43 == *((const U8*)s - 2) ) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
: ((s) - (e) > 1) ?                                                         \
    ( ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || '\n' == *((const U8*)s - 1) || 0x25 == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( ( 0x41 == *((const U8*)s - 1) ) && ( 0x80 == *((const U8*)s - 2) ) ) ? 2 : 0 )\
: ((s) - (e) > 0) ?                                                         \
    ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || '\n' == *((const U8*)s - 1) || 0x25 == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) )\
: 0 )

#endif	/* EBCDIC 1047 */

#if 'A' == 193 /* EBCDIC 037 */ \
     && '\\' == 224 && '[' == 186 && ']' == 187 && '{' == 192 && '}' == 208 \
     && '^' == 176 && '~' == 161 && '!' == 90 && '#' == 123 && '|' == 79 \
     && '$' == 91 && '@' == 124 && '`' == 121 && '\n' == 37
/*
	SPACE: Backwards \p{XPerlSpace}

	\p{XPerlSpace}
*/
/*** GENERATED CODE ***/
#define is_SPACE_utf8_safe_backwards(s,e)                                   \
( ((s) - (e) > 2) ?                                                         \
    ( ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || 0x15 == *((const U8*)s - 1) || '\n' == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( 0x41 == *((const U8*)s - 1) ) ?                                     \
	( ( 0x41 == *((const U8*)s - 2) ) ?                                 \
	    ( ( ( *((const U8*)s - 3) & 0xFB ) == 0xCA ) ? 3 : 0 )          \
	: ( 0x62 == *((const U8*)s - 2) ) ?                                 \
	    ( ( 0xBD == *((const U8*)s - 3) ) ? 3 : 0 )                     \
	: ( 0x78 == *((const U8*)s - 2) ) ? 2 : 0 )                         \
    : ( inRANGE_helper_(U8, *((const U8*)s - 1), 0x42, 0x48) || 0x51 == *((const U8*)s - 1) ) ?\
	( ( ( 0x41 == *((const U8*)s - 2) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( inRANGE_helper_(U8, *((const U8*)s - 1), 0x49, 0x4A) ) ?            \
	( ( ( inRANGE_helper_(U8, *((const U8*)s - 2), 0x41, 0x42) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( 0x56 == *((const U8*)s - 1) ) ?                                     \
	( ( ( 0x42 == *((const U8*)s - 2) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
    : ( ( ( 0x72 == *((const U8*)s - 1) ) && ( 0x43 == *((const U8*)s - 2) ) ) && ( 0xCA == *((const U8*)s - 3) ) ) ? 3 : 0 )\
: ((s) - (e) > 1) ?                                                         \
    ( ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || 0x15 == *((const U8*)s - 1) || '\n' == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) ) ? 1\
    : ( ( 0x41 == *((const U8*)s - 1) ) && ( 0x78 == *((const U8*)s - 2) ) ) ? 2 : 0 )\
: ((s) - (e) > 0) ?                                                         \
    ( '\t' == *((const U8*)s - 1) || inRANGE_helper_(U8, *((const U8*)s - 1), '\v', '\r') || 0x15 == *((const U8*)s - 1) || '\n' == *((const U8*)s - 1) || ' ' == *((const U8*)s - 1) )\
: 0 )

#endif	/* EBCDIC 037 */
