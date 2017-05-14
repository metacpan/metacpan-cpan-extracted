#include "stdlib.h"
#include "stdio.h"
#include <unicode/urep.h>
#include <unicode/utypes.h>
#include <unicode/utrans.h>
#include <unicode/utf.h>


/**
 * Transliterates string using transliterator with id 'id' using direction dir
 *
 * @param id - transliterator string identifier
 * @param dir - transliterator direction, can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param string - UTF-8 string that needs be transliterated
 * @param err_PTR - pointer to error code, must be initialized to U_ZERO_ERROR
 * @returns - UTF-16 transliterated newly allocated string
 **/
U_CAPI char* U_EXPORT2 utf8_transliterate_MALLOC (const char* id, const UTransDirection dir, const char* utf8_string,  int* err_PTR);


/**
 * Transliterates string using transliterator with id 'id' using direction dir
 *
 * @param id - transliterator string identifier
 * @param dir - transliterator direction, can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param string - UTF-16 string that needs be transliterated
 * @param err_PTR - pointer to error code, must be initialized to U_ZERO_ERROR
 * @returns - UTF-16 transliterated newly allocated string
 **/
U_CAPI UChar* U_EXPORT2 utf16_transliterate_MALLOC (const char* id, const UTransDirection dir, const UChar* string, int* err_PTR);


/**
 * Processes string using transliterator, and returns a newly allocated UChar* string
 *
 * @param transliterator - The transliterator to use
 * @param string - The string to transliterate
 * @returns - The transliterated string
 **/
U_CAPI UChar* U_EXPORT2 utf16_transliterate_useTransliterator_MALLOC (const UTransliterator* transliterator, const UChar* string, int* err_PTR);


/**
 * Allocates and returns a new transliterator
 *
 * @param id - Transliterator ID to open
 * @param dir - Direction, which can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated UChar* String that need be freed at some point
 **/
U_CAPI UTransliterator* U_EXPORT2 utf16_transliterate_openTransliterator_MALLOC (const char* id, const UTransDirection dir, int* err_PTR);


/**
 * Converts a char* UTF-8 string into a UChar* UTF-16 string
 *
 * @param src - the UTF-8 const char* string to convert
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated UChar* UTF-16 String
 **/
U_CAPI UChar* U_EXPORT2 convert_utf8_to_utf16_MALLOC (const char* src, int* err_PTR);


/**
 * Converts a UChar* UTF-16 string into a char* UTF-8 string
 *
 * @param src - the UTF-16 const UCHar* string to convert
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated char* UTF-8 string 
 **/
U_CAPI char* U_EXPORT2 convert_utf16_to_utf8_MALLOC (const UChar* src, int* err_PTR);


U_CAPI void U_EXPORT2 checkErrorCode (int* errorCode_PTR);








