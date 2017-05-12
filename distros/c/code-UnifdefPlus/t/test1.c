/* Test1.c -- test for unifdef+ for c/c++.  Should produce test1.c.out
 * with -D FOO -D D1=1 -D D2=2 -U BAR -U U1 -U U2 */


/* 1. basic tests of #if, #ifdef, #ifndef: */
#ifdef FOO
/* 1.1. FOO defined (V) */
#endif

#ifndef FOO
/* 1.2 FOO not defined (I) */
#endif

#if defined(FOO)
/* 1.3 FOO defined (V) */
#endif

#if defined FOO   // EOL comment 4
/* 1.4 FOO defined (V) */
#else
/* 1.4 FOO not defined */
#endif // EOL comment 4

#ifdef BAR
/* 1.5 BAR defined (I) */
#endif

#ifndef BAR
/* 1.6 BAR not defined (V) */
#endif

#if defined(BAR)
/* 1.7 BAR defined (I) */
#endif

#if defined BAR   // EOL comment 8
/* 1.8 BAR defined (I) */
#else
/* 1.8 BAR NOT defined */
#endif // EOL comment 8

#ifdef FOOBAR
/* 1.9 FOOBAR defined (V) */
#endif

#ifndef FOOBAR
/* 1.10 FOOBAR not defined (V) */
#endif

#if defined(FOOBAR)
/* 1.11 FOOBAR defined (V) */
#endif

#if defined FOOBAR   // EOL comment 12
/* 1.12 FOOBAR defined (V)*/
#else
/* 1.12 FOOBAR not defined (V) */
#endif // EOL comment 12

#if (D1 == 1) // (I)
/* 1.13 D1 is 1 */
#endif // (I)

#if (D1 == 2)  // (I)
/* 1.14 D1 is 2 */
#endif // (I)


/* 2.  Checking #elif statements */
#if defined FOO // (I)
/* 2.1  FOO defined (V) */
#elif defined BAR // (I)
/* 2.1 FOO not defined, BAR defined (I) */
#elif defined FOOBAR // (I)
/* 2.1 FOO and BAR not defined, FOOBAR defined (I) */
#else // (I)
/* 2.1 FOO, BAR and FOOBAR not defined (I) */
#endif // (I)

#if defined BAR  // (I)
/* 2.2  BAR defined (I)*/
#elif defined FOO  // (I)
/* 2.2  BAR not defined, FOO defined (V) */
#elif defined FOOBAR  // (I)
/* 2.2  BAR and FOO not defined, FOOBAR defined */
#else  // (I)
/* 2.2  BAR and FOO and FOOBAR not defined */
#endif  // (I)

#if defined FOOBAR  // (V)
/* 2.3  FOOBAR defined (V) */
#elif defined FOOBAR2 // (V)
/* 2.3  FOOBAR not defined, FOOBAR2 defined (V) */
#else // (V)
/* 2.3  FOOBAR and FOOBAR2 not defined (V) */
#endif // (V)



/* Checking that #ifs in comment are not simplified:
#if defined BAR
  ... some text
#endif
 */
// #if defined BAR
//    some comment
// #endif

/* 3. Check nesting: */

#if defined FOO
#if defined BAR
/* 3.1 FOO and BAR defined (I) */
#else
/* 3.1 FOO defined, but not BAR (V) */
#endif
#if defined FOOBAR
/* 3.1 FOO and FOOBAR defined (V) */
#else
/* 3.1 FOO defined but not FOOBAR (V) */
#endif
#else
#if defined FOOBAR
/* 3.1 FOO not defined, FOOBAR defined (I) */
#else
/* 3.1 FOO and FOOBAR not defined (I) */
#endif
#endif

#if defined BAR // (I)
#if defined FOO // (I)
/* 3.6 FOO and BAR defined (I) */
#else // (I)
/* 3.7 BAR defined, but not FOO (I) */
#endif // (I)
#if defined FOOBAR // (I)
/* 3.8 BAR and FOOBAR defined (I) */
#else // (I)
/* 3.9 BAR defined but not FOOBAR (I) */
#endif // (I)
#else // (I)
#if defined FOOBAR //(V)
/* 3.1 BAR not defined, FOOBAR defined (V) */
#else //(V)
/* 3.1 BAR and FOOBAR not defined (V) */
#endif //(V)
#endif //(I)

/* 4:  Check complex expressions with #if:  */
// note: && has higher precedence than ||:

#if defined(FOO) && defined(BAR)
/* 4.1 FOO and BAR are defined (I)*/
#else
/* 4.1 FOO or BAR are undefined (V) */
#endif

#if defined(FOO) || defined(BAR)
/* 4.2 FOO or BAR are defined (V) */
#else
/* 4.2 FOO and BAR are undefined (I) */
#endif

#if defined(D1) && defined(D2) || defined(U1)
/* 4.3 #if defined(D1) && defined(D2) || defined(U1) (V)*/
#else
/* 4.3 #else (I) */
#endif


#if defined(D1) || defined(D2) && defined(U1)
/* 4.4 #if defined(D1) || defined(D2) && defined(U1) (V) */
#else
/* 4.4 #else (I) */
#endif

#if (defined(D1) || defined(D2)) && defined(U1)
/* 4.5 #if (defined(D1) || defined(D2)) && defined(U1) (I) */
#else
/* 4.5 #else (#if (defined(D1) || defined(D2)) && defined(U1)) (V)*/
#endif

#if (defined(D1) || defined(D2)) && defined(U1) || defined(FOOBAR)
/* 4.6 #if (defined(D1) || defined(D2)) && defined(U1) || defined(FOOBAR) (V) */
#else
/* 4.6 #else */
#endif



#if (D2 * 2 - 1 > D1 + 1 ) \
	&& (defined(FOO) || defined(FOOBAR)) \
	&& (FOOBAR > 3 * (9 - 2) ) // eol comment
/* 4.20 complex... -- should resolve to #if ( FOOBAR > 3 * (9 - 2) ) // eol comment */
#else
/* 4.20 #else */
#endif

#if  ( defined(U1) && defined(UNKNOWN1) ) || \
       !defined D1  // resolves to false
    /* 4.21 line will NOT appear */
#elif D1 <= 3 && U1 > (3 + 2)   // (4.21 condition simplifies)
    /* 4.21 line will appear */
#elif D1 > 3  // condition resolves to false (1 < 3...)
    /* 4.21 line will NOT appear */
#else
    /* 4.21 line will appear, as an else to the unknown */
#endif


// Note: known bug: whitespace at opening brace is not being preserved...
// #if ( ( /*comment*/ FOOBAR > 3 * (9-2)) && defined(FOO) )
// does not preserve the comment or whitespaces.


