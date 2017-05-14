/**
 * transwrap.c - wrapper for ICU 2.0 transliteration services
 *
 * ===================================
 * CONVENTIONS ABOUT MEMORY MANAGEMENT
 * ===================================
 *
 * Within functions:
 *
 *   . A call to a function that allocates something, must be marked as
 *     a comment saying MALLOC
 *
 *   . A call to a function that frees something, must be marked as
 *     a comment saying FREE
 *
 *   . All functions should have as many MALLOC as FREE comments
 *
 *   . If a function name ends with _MALLOC, then we have to
 *     add a FREE comment at the end of the function
 *
 *   . If a function name ends with _FREE, then we have to
 *     add a MALLOC comment at the beginning of the function
 *
 *   Sorry for being so paranoid, I don't want my mod_perl processes to
 *   get bigger than they are :-)
 **/
#include "stdlib.h"
#include "stdio.h"
#include <unicode/urep.h>
#include <unicode/utypes.h>
#include <unicode/utrans.h>
#include <unicode/utf.h>


U_CAPI char* U_EXPORT2 utf8_transliterate_MALLOC (const char* id,const UTransDirection dir, const char* utf8_string,  int* err_PTR);
U_CAPI UChar* U_EXPORT2 utf16_transliterate_MALLOC (const char* id, const UTransDirection dir, const UChar* string, int* err_PTR);
U_CAPI UChar* U_EXPORT2 utf16_transliterate_useTransliterator_MALLOC (const UTransliterator* transliterator, const UChar* string, int* err_PTR);
U_CAPI UTransliterator* U_EXPORT2 utf16_transliterate_openTransliterator_MALLOC (const char* id, const UTransDirection dir, int* err_PTR);
U_CAPI UChar* U_EXPORT2 convert_utf8_to_utf16_MALLOC (const char* src, int* err_PTR);
U_CAPI char* U_EXPORT2 convert_utf16_to_utf8_MALLOC (const UChar* src, int* err_PTR);
U_CAPI void U_EXPORT2 checkErrorCode (int* errorCode_PTR);


/*
int main()
{
  int   errorCode       = U_ZERO_ERROR;
  int*  errorCode_PTR   = (int*) &errorCode;
  char* orig            = "Compyutaa";
  char* orig_trans      = NULL;
  char* orig_trans_orig = NULL;
  
  orig_trans = utf8_transliterate_MALLOC ("Latin-Katakana", UTRANS_FORWARD, orig, errorCode_PTR);
  if (errorCode_PTR > U_ZERO_ERROR) checkErrorCode (errorCode_PTR);
  errorCode = U_ZERO_ERROR;
  
  orig_trans_orig = utf8_transliterate_MALLOC ("Latin-Katakana", UTRANS_REVERSE, orig_trans, errorCode_PTR);
  if (errorCode_PTR > U_ZERO_ERROR) checkErrorCode (errorCode_PTR);
  errorCode = U_ZERO_ERROR;
  
  printf ("%s : %s : %s", orig, orig_trans, orig_trans_orig);
}
*/



/**
 * Transliterates string using transliterator with id 'id' using direction dir
 *
 * @param id - transliterator string identifier
 * @param dir - transliterator direction, can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param string - UTF-8 string that needs be transliterated
 * @param err_PTR - pointer to error code, must be initialized to U_ZERO_ERROR
 * @returns - UTF-16 transliterated newly allocated string
 **/
U_CAPI char* U_EXPORT2 utf8_transliterate_MALLOC (const char* id, const UTransDirection dir, const char* utf8_string,  int* err_PTR)
{
  UChar* utf16_string  = NULL;
  UChar* utf16_result  = NULL;
  char*  utf8_result   = NULL;
  int    errorCode     = U_ZERO_ERROR;
  int*   errorCode_PTR = &errorCode;
  
  /* MALLOC <utf16_string> */
  /* Converts string into UTF-16 */
  utf16_string = convert_utf8_to_utf16_MALLOC (utf8_string, errorCode_PTR);
  if (errorCode > U_ZERO_ERROR) {
    *err_PTR = errorCode;
    fprintf (stderr, "utf8_transliterate_MALLOC: convert_utf8_to_utf16_MALLOC\n");
    if (utf16_string != NULL) free (utf16_string);
    return NULL;
  }
  errorCode = U_ZERO_ERROR;
  
  /* MALLOC <utf16_result> */
  /* Transliterates utf16_string into result */
  utf16_result = utf16_transliterate_MALLOC (id, dir, utf16_string, errorCode_PTR);
  if (errorCode > U_ZERO_ERROR) {
    *err_PTR = errorCode;
    fprintf (stderr, "utf8_transliterate_MALLOC: utf16_transliterate_MALLOC\n");
    if (utf16_string != NULL) free (utf16_string);
    if (utf16_result != NULL) free (utf16_result);
    return NULL;
  }
  errorCode = U_ZERO_ERROR;
  
  /* MALLOC <utf8_result> */
  utf8_result = convert_utf16_to_utf8_MALLOC (utf16_result, errorCode_PTR);
  if (errorCode > U_ZERO_ERROR) {
    fprintf (stderr, "utf8_transliterate_MALLOC: convert_utf16_to_utf8_MALLOC\n");
    if (utf16_string != NULL) free (utf16_string);
    if (utf16_result != NULL) free (utf16_result);
    if (utf8_result  != NULL) free (utf8_result);
    return NULL;
  }
  errorCode = U_ZERO_ERROR;
  
  /* FREE <utf16_string> */
  free (utf16_string);
  
  /* FREE <utf16_result> */
  free (utf16_result);
  
  /* FREE <utf8_result> (delayed) */
  return utf8_result;
}


/**
 * Transliterates string using transliterator with id 'id' using direction dir
 *
 * @param id - transliterator string identifier
 * @param dir - transliterator direction, can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param string - UTF-16 string that needs be transliterated
 * @param err_PTR - pointer to error code, must be initialized to U_ZERO_ERROR
 * @returns - UTF-16 transliterated newly allocated string
 **/
U_CAPI UChar* U_EXPORT2 utf16_transliterate_MALLOC (const char* id, const UTransDirection dir, const UChar* string, int* err_PTR)
{
  UChar*           result         = NULL;
  int              errorCode      = U_ZERO_ERROR;
  int*             errorCode_PTR  = &errorCode;
  UTransliterator* transliterator = NULL;
  
  /* MALLOC <transliterator> */
  /* opens transliterator */
  transliterator = utf16_transliterate_openTransliterator_MALLOC (id, dir, errorCode_PTR);
  if (errorCode > U_ZERO_ERROR) {
    *err_PTR = errorCode;
    fprintf (stderr, "utf16_transliterate_MALLOC: utf16_transliterate_openTransliterator_MALLOC\n");
    if (transliterator != NULL) free (transliterator);
    return NULL;
  }
  
  /* MALLOC <result> */
  /* transliterates the result */
  result = utf16_transliterate_useTransliterator_MALLOC (transliterator, string, err_PTR);
  if (*err_PTR > U_ZERO_ERROR) {
    fprintf (stderr, "utf16_transliterate_MALLOC: utf16_transliterate_useTransliterator_MALLOC\n");
    if (transliterator != NULL) free (transliterator);
    if (result != NULL) free (result);
    return NULL;
  }
  
  /* FREE <transliterator> */
  /* closes transliterator */
  utrans_close (transliterator);
  
  return result;
  /* FREE <result> (delayed) */
}


/**
 * Processes string using transliterator, and returns a newly allocated UChar* string
 *
 * @param transliterator - The transliterator to use
 * @param string - The string to transliterate
 * @returns - The transliterated string
 **/
U_CAPI UChar* U_EXPORT2 utf16_transliterate_useTransliterator_MALLOC (const UTransliterator* transliterator, const UChar* string, int* err_PTR)
{
  UChar*   text           = NULL;
  int32_t  textLength     = -1;
  int32_t* textLength_PTR = &textLength;
  int32_t  textCapacity   = 0;
  int32_t  start          = 0;
  int32_t  limit          = u_strlen (string);
  int32_t* limit_PTR      = &limit;
  int      errorCode      = U_ZERO_ERROR;
  int*     errorCode_PTR  = &errorCode;
  
  errorCode = U_BUFFER_OVERFLOW_ERROR;
  
  /*
    As long as we have not allocated a buffer which
    is large enough, let's try to reallocate a bigger
    buffer
    
    MALLOC <result>
  */
  while (errorCode == U_BUFFER_OVERFLOW_ERROR) {
    
    errorCode = U_ZERO_ERROR;
    if (textCapacity == 0) textCapacity = u_strlen (string) + 1;
    else                   textCapacity *= 2;
    
    /* MALLOC <text> */
    /* performs some initialization */
    if (text != NULL) free (text);
    text = (UChar*) malloc (textCapacity * sizeof (UChar));
    u_strcpy (text, string);
    
    /* performs the UChar transliteration */
    utrans_transUChars ( transliterator,
			 text,
			 textLength_PTR,
			 textCapacity,
			 start,
			 limit_PTR,
			 errorCode_PTR );
    
    /* We want the string to be zero-terminated */
    if (textCapacity == *textLength_PTR) errorCode = U_BUFFER_OVERFLOW_ERROR;
  }
  
  *err_PTR = U_ZERO_ERROR;
  if (errorCode != U_ZERO_ERROR) {
    free (text);
    text = NULL;
  }

  return text;
  /* FREE <text> (delayed) */
}


/**
 * Allocates and returns a new transliterator
 *
 * @param id - Transliterator ID to open
 * @param dir - Direction, which can be UTRANS_FORWARD or UTRANS_REVERSE
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated UChar* String that need be freed at some point
 **/
U_CAPI UTransliterator* U_EXPORT2 utf16_transliterate_openTransliterator_MALLOC (const char* id, const UTransDirection dir, int* err_PTR)
{
  int              errorCode      = U_ZERO_ERROR;
  int*             errorCode_PTR  = (int*) &errorCode;
  UTransliterator* transliterator = NULL;
  
  /* Attempts to open the transliterator */
  /* MALLOC <transliterator> */
  transliterator = utrans_open ( id,
				 dir,
				 NULL,
				 -1,
				 NULL,
				 errorCode_PTR );
  
  /* If the open failed, set error code and return NULL */
  *err_PTR = errorCode;
  if (errorCode > U_ZERO_ERROR) {
    if (transliterator != NULL) free (transliterator);
    return NULL;
  }
  
  return transliterator;
  /* FREE <transliterator> (delayed) */
}


/**
 * Converts a char* UTF-8 string into a UChar* UTF-16 string
 *
 * @param src - the UTF-8 const char* string to convert
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated UChar* UTF-16 String
 **/
U_CAPI UChar* U_EXPORT2 convert_utf8_to_utf16_MALLOC (const char* src, int* err_PTR)
{
  UChar*   result         = NULL;
  int32_t  destCapacity   = 0;
  int32_t  destLength     = 0;
  int32_t* destLength_PTR = &destLength;
  int32_t  srcLength      = -1;
  int      errorCode      = U_ZERO_ERROR;
  int*     errorCode_PTR  = (int*) &errorCode; 
  
  errorCode = U_BUFFER_OVERFLOW_ERROR;
  
  /*
    As long as we have not allocated a buffer which
    is large enough, let's try to reallocate a bigger
    buffer
    
    MALLOC <result>
  */
  while (errorCode == U_BUFFER_OVERFLOW_ERROR) {
    
    errorCode = U_ZERO_ERROR;
    if (destCapacity == 0) destCapacity = u_strlen (src) + 1;
    else                   destCapacity *= 2;
    
    destLength   = 0;
    if (result != NULL) free (result);
    result = (UChar*) malloc ((destCapacity) * sizeof (UChar));
    
    /* Converts string to UTF-8 */
    u_strFromUTF8 ( result,
		    destCapacity,
		    destLength_PTR,
		    src,
		    srcLength,
		    errorCode_PTR );
    
    /* We want the string to be zero-terminated */
    if (destCapacity == *destLength_PTR) errorCode = U_BUFFER_OVERFLOW_ERROR;
  }
  
  *err_PTR = errorCode;
  if (errorCode != U_ZERO_ERROR) {
    free (result);
    result = NULL;
  }
  
  return result;
  /* FREE <result> (delayed) */
}


/**
 * Converts a UChar* UTF-16 string into a char* UTF-8 string
 *
 * @param src - the UTF-16 const UCHar* string to convert
 * @param err_PTR - a pointer to an int value
 * @returns a newly allocated char* UTF-8 string 
 **/
U_CAPI char* U_EXPORT2 convert_utf16_to_utf8_MALLOC (const UChar* src, int* err_PTR)
{
  char*    result         = NULL;
  int32_t  destCapacity   = 0;
  int32_t  destLength     = 0;
  int32_t* destLength_PTR = &destLength;
  int32_t  srcLength      = -1;
  int      errorCode      = U_ZERO_ERROR;
  int*     errorCode_PTR  = (int*) &errorCode;
  
  errorCode = U_BUFFER_OVERFLOW_ERROR;
  
  /*
    As long as we have not allocated a buffer which
    is large enough, let's try to reallocate a bigger
    buffer
    
    MALLOC <result>
  */
  while (errorCode == U_BUFFER_OVERFLOW_ERROR) {
    
    errorCode = U_ZERO_ERROR;
    if (destCapacity == 0) destCapacity = u_strlen (src) + 1;
    else                   destCapacity *= 2;
    
    destLength   = 0;
    if (result != NULL) free (result);
    result = (char*) malloc ((destCapacity) * sizeof (char));
    
    /* Converts string to UTF-8 */
    u_strToUTF8 ( result,
		  destCapacity,
		  destLength_PTR,
		  src,
		  srcLength,
		  errorCode_PTR );

    /* We want the string to be zero-terminated */
    if (destCapacity == *destLength_PTR) errorCode = U_BUFFER_OVERFLOW_ERROR;
  }
  
  *err_PTR = errorCode;
  if (errorCode != U_ZERO_ERROR) {
    free (result);
    result = NULL;
  }
  
  return result;
  /* FREE <result> (delayed) */
}


/**
 * Just a bit of debug...
 * This subroutine has been greatly simplified thanks to Ram Viswanadha <ram@jtcsv.com>
 **/
U_CAPI void U_EXPORT2 checkErrorCode (int* errorCode_PTR)
{
  int errorCode = *errorCode_PTR;  
  fprintf (stderr, "%d: %s \n", errorCode, u_errorName(errorCode));
}


