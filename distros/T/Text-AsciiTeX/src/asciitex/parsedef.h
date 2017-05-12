/* parsedef.h: header for parsing keqword tables */

/*  This file is part of asciiTeX.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; see the file COPYING.  If not, write to
      The Free Software Foundation, Inc.
      59 Temple Place, Suite 330
      Boston, MA 02111 USA
      
    
    Authors:
    Original program (eqascii): Przemek Borys
    Fork by: Bart Pieters
       
*************************************************************************/

#ifndef PARSEDEF
#define PAREDEF
/*
 * to add keywords: 1 add an element to the list below 2 add a
 * recognision pattern to the key table in dim.c 3 add the case for your 
 * element to the dim routine 4 write your routine, let it add the list
 * element to the gpos vector 5 call your routine from the draw routine
 * 
 */

typedef enum {
	/*
	 * misk 
	 */
	ERR,
	ESCAPE,
	/*
	 * things with children 
	 */
	FRAC,
	SUPER,
	SUB,
	SQRT,
	OVERLINE,
	UNDERLINE,
	LIMIT,
	BRACES,
	ARRAY,
	/*
	 * symbols 
	 */
	TO,
	LEADSTO,
	SUM,
	PROD,
	INT,
	OINT,
	INFTY,
	LCEIL,
	RCEIL,
	LFLOOR,
	RFLOOR
} PRSDEF;
typedef struct {
	char           *name;
	int             len;
	PRSDEF          Nr;
} KEYWORD;

/* the keword table in dim.c */

#endif
