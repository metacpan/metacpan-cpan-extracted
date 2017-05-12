#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ft2build.h>
#include FT_FREETYPE_H

FT_Library library;
FT_Face face;
FT_Bitmap ftbBitmap;

MODULE = FONT::FT2		PACKAGE = FONT::FT2		

char *
init(FONT)
	char * FONT
  CODE:
	int error;
	int error2;
    error = FT_Init_FreeType( &library );
    error2 = FT_New_Face( library,
			FONT,
                         0,
                         &face );
     if ( error2 )
	{
		RETVAL = "FAILED";
	} else {
		RETVAL = "SUCCESS";
	}

  OUTPUT:
    RETVAL

long
get_glyph_index(charcode)
	long charcode;
  CODE:
    int glyph_index;

     glyph_index = FT_Get_Char_Index( face, charcode );
	RETVAL = glyph_index;

  OUTPUT:
    RETVAL

long
set_transform(angle, height, width)
	double angle;
	unsigned long height;
	unsigned long width;
  CODE:
	FT_Matrix	matrix;
	matrix.xx = (FT_Fixed)(cos(angle)*width);
	matrix.xy = (FT_Fixed)(-sin(angle)*height);
	matrix.yx = (FT_Fixed)(-sin(angle)*width);
	matrix.yy = (FT_Fixed)(cos(angle)*height);
             
	FT_Set_Transform(
                   face,       
                   &matrix,   
                   NULL);
	RETVAL = 1;
  OUTPUT:
	RETVAL

char *
render(glyph_index)
	int glyph_index;
  CODE:
    int error;

     error = FT_Load_Glyph( 
              face,          
              glyph_index,   
              1 );

     if ( error )
	{
		printf ("GET CHAR INDEX NOT OK!\n");
	}

     error = FT_Render_Glyph(
                  face->glyph,      /* glyph slot  */
                  1 );    /* render mode */
     if ( error )
	{
		printf ("Render Glyph NOT OK!\n");
	}


	RETVAL = NULL;

  OUTPUT:
    RETVAL

long
height(glyph_index)
	long glyph_index;
  CODE:
 	ftbBitmap = face->glyph->bitmap; 
	RETVAL = ftbBitmap.rows;

  OUTPUT:
    RETVAL

long
width(glyph_index)
	long glyph_index;
  CODE:
	ftbBitmap = face->glyph->bitmap; 
	RETVAL = ftbBitmap.width;

  OUTPUT:
    RETVAL

char
get_byte(index)
	int index
  CODE:
	RETVAL = ftbBitmap.buffer[index];
	
  OUTPUT:
	RETVAL
