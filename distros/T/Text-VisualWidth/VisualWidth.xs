#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

int count_single_char_eucjp( const unsigned char** pos, int* byte ){
  *byte = 0;
  if( **pos == 0 ) return 0;
  if( **pos == 0x8e ){
    (*pos)++;
    (*byte)++;
    if( **pos >= 0xa1 && **pos <= 0xfe ) { (*pos)++; (*byte)++; }
    return 1;
  }else if( **pos == 0x8f ){
    (*pos)++; (*byte)++;
    if( **pos >= 0xa1 && **pos <= 0xfe ) { (*pos)++; (*byte)++; }
    if( **pos >= 0xa1 && **pos <= 0xfe ){
      (*pos)++;
      (*byte)++;
      return 2;
    }
    return 1;
  }else if( **pos >= 0xa1 && **pos <= 0xfe ){
    (*pos)++;
    (*byte)++;   
    if( **pos >= 0xa1 && **pos <= 0xfe ){
      (*pos)++;
      (*byte)++;   
      return 2;
    }
    return 1;
  }
  (*pos)++;
  (*byte)++; 
  return 1;
}

SV* get_visualwidth_eucjp( SV* str ){
  unsigned int length = 0;
  int byte = 0;
  const unsigned char* pos = (const unsigned char*)SvPV_nolen(str);
  const unsigned char** posstr = &pos;
  while( **posstr ){
    length += count_single_char_eucjp( posstr, &byte );
  }
  return newSViv(length);
}

SV* trim_visualwidth_eucjp( SV* str, SV* length_sv ){
  unsigned int length = SvIV(length_sv);
  int byte = 0;
  unsigned int byte_length = 0;
  unsigned int view_length = 0;
  int view_char = 0;
  int continue_flg = 1;
  unsigned char* default_pos = (unsigned char *)SvPV_nolen(str);  
  unsigned char* pos = default_pos;
  unsigned char** posstr = &pos;
  while( continue_flg ){
    view_char = count_single_char_eucjp( (const unsigned char **)posstr, &byte );
    if( byte && ( view_char + view_length ) <= length ){
      view_length += view_char;
      byte_length += byte; 
    }else{
      continue_flg = 0;
    }
  }
  return newSVpvn((const char *)default_pos , byte_length);
}

int count_single_char_utf8( const unsigned char** pos, int* byte ){
  *byte = 0;
  if( **pos == 0 ) return 0;
  if( **pos == 0xef && *((*pos)+1) == 0xbb && *((*pos)+2) == 0xbf ){
    // BOM
    (*pos)+= 3;
    (*byte)+= 3;
//    printf("BOM\n");
    return 0;
  } else if( ( **pos & 0xe0 ) == 0xc0 && ( ( *((*pos)+1) & 0xc0 ) == 0x80 ) ){
    (*pos)+= 2;
    (*byte)+= 2;
//    printf("2byte\n");
    return 1;
  } else if( ( **pos & 0xf0 ) == 0xe0 && ( ( *((*pos)+1) & 0xc0 ) == 0x80 ) && ( ( *((*pos)+2) & 0xc0 ) == 0x80 ) ){
    if( **pos == 0xef && ( ( *((*pos)+1) == 0xbd && *((*pos)+2) >= 0xa1 && *((*pos)+2) <= 0xbf )
                      || ( *((*pos)+1) == 0xbe && *((*pos)+2) >= 0x80 && *((*pos)+2) <= 0x9f ) ) ){
      (*pos)+= 3;
      (*byte)+= 3;
//      printf("HALFWIDTH\n");
      return 1;
    }  
    (*pos)+= 3;
    (*byte)+= 3;
//    printf("FULLWIDTH\n");
    return 2;
  } else if( ( **pos & 0xf8 ) == 0xf0 && ( ( *((*pos)+1) & 0xc0 ) == 0x80 ) 
           && ( ( *((*pos)+2) & 0xc0 ) == 0x80 ) && ( ( *((*pos)+3) & 0xc0 ) == 0x80 )){
    (*pos)+= 4;
    (*byte)+= 4;
//    printf("4byte\n");
    return 2;
  }
  (*pos)++;
  (*byte)++;
//   printf("SINGLE\n");
  return 1;
}

SV* get_visualwidth_utf8( SV* str ){
  unsigned int length = 0;
  int byte = 0;
  const unsigned char* pos = (const unsigned char*)SvPV_nolen(str);
  const unsigned char** posstr = &pos;
  while( **posstr ){
    length += count_single_char_utf8( posstr, &byte );
  }
  return newSViv(length);
}

SV* trim_visualwidth_utf8( SV* str, SV* length_sv ){
  unsigned int length = SvIV(length_sv);
  int byte = 0;
  unsigned int byte_length = 0;
  unsigned int view_length = 0;
  int view_char = 0;
  int continue_flg = 1;
  unsigned char* default_pos = (unsigned char *)SvPV_nolen(str);  
  unsigned char* pos = default_pos;
  unsigned char** posstr = &pos;
  while( continue_flg ){
    view_char = count_single_char_utf8( (const unsigned char **)posstr, &byte );
    if( byte && ( view_char + view_length ) <= length ){
      view_length += view_char;
      byte_length += byte; 
    }else{
      continue_flg = 0;
    }
  }
  return newSVpvn((const char *)default_pos , byte_length);
}


MODULE = Text::VisualWidth		PACKAGE = Text::VisualWidth::EUC_JP
PROTOTYPES: ENABLE

SV *
xs_get_visualwidth_eucjp( str )
		SV * str
CODE:
    RETVAL = get_visualwidth_eucjp(str);
OUTPUT:
    RETVAL

SV *
xs_trim_visualwidth_eucjp( str, length_sv )
		SV * str
		SV * length_sv
CODE:
    RETVAL = trim_visualwidth_eucjp(str, length_sv);
OUTPUT:
    RETVAL

MODULE = Text::VisualWidth		PACKAGE = Text::VisualWidth::UTF8
PROTOTYPES: ENABLE

SV *
xs_get_visualwidth_utf8( str )
		SV * str
CODE:
    RETVAL = get_visualwidth_utf8(str);
OUTPUT:
    RETVAL

SV *
xs_trim_visualwidth_utf8( str, length_sv )
		SV * str
		SV * length_sv
CODE:
    RETVAL = trim_visualwidth_utf8(str, length_sv);
OUTPUT:
    RETVAL
