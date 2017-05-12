#include <libxml/parser.h>

/** 
 * encodeString returns an UTF-8 encoded String
 * while the encodig has the name of the encoding of string
 **/ 
xmlChar*
domEncodeString( const char *encoding, const char *string ){
  xmlCharEncoding enc;
  xmlChar *ret = NULL;

  if ( string != NULL ) {
    if( encoding != NULL ) {
      enc = xmlParseCharEncoding( encoding );
      if ( enc > 0 ) {
        if( enc > 1 ) {
          xmlBufferPtr in, out;
          xmlCharEncodingHandlerPtr coder ;
          in  = xmlBufferCreate();
          out = xmlBufferCreate();
          
          coder = xmlGetCharEncodingHandler( enc );
          
          xmlBufferCCat( in, string );
          
          if ( xmlCharEncInFunc( coder, out, in ) >= 0 ) {
            ret = xmlStrdup( out->content );
          }
          else {
            /* printf("encoding error\n"); */
          }
          
          xmlBufferFree( in );
          xmlBufferFree( out );
        }
        else {
          /* if utf-8 is requested we do nothing */
          ret = xmlStrdup( string );
        }
      }
      else {
        /* printf( "encoding error: no enciding\n" ); */
      }
    }
    else {
      /* if utf-8 is requested we do nothing */
      ret = xmlStrdup( string );
    }
  }
  return ret;
}

/**
 * decodeString returns an $encoding encoded string.
 * while string is an UTF-8 encoded string and 
 * encoding is the coding name
 **/
char*
domDecodeString( const char *encoding, const xmlChar *string){
  char *ret=NULL;
  xmlBufferPtr in, out;
 
  if ( string != NULL ) {
    if( encoding != NULL ) {
      xmlCharEncoding enc = xmlParseCharEncoding( encoding );
      /*      printf("encoding: %d\n", enc ); */
      if ( enc > 0 ) {
        if( enc > 1 ) {
          xmlBufferPtr in, out;
          xmlCharEncodingHandlerPtr coder;
          in  = xmlBufferCreate();
          out = xmlBufferCreate();

          coder = xmlGetCharEncodingHandler( enc );
          xmlBufferCat( in, string );        
          
          if ( xmlCharEncOutFunc( coder, out, in ) >= 0 ) {
            ret=xmlStrdup(out->content);
          }
          else {
            /* printf("decoding error \n"); */
          }

          xmlBufferFree( in );
          xmlBufferFree( out );
        }
        else {
          ret = xmlStrdup(string);
        }
      }
      else {
        /* printf( "decoding error:no encoding\n" ); */
      }
    }
    else {
      /* if utf-8 is requested we do nothing */
      ret = xmlStrdup( string );
    }
  }
  return ret;
}

