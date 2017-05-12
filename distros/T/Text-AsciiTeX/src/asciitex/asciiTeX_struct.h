/* asciiTeX_struct.h: Global definition of structures needed in all layout/
   dimentioning and drawing routines */

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

#ifndef ASCIITEXSTRUCT_H
#define ASCIITEXSTRUCT_H

typedef struct {
	int             x;	/* width, counting from 0 (left) to x (right) */
	int             y;	/* height, counting from 0 (top) to y (bottom) */
	int             baseline;	/* default line for single
					 * characters counting from down (i.e. y value of this line is dim.y-baseline) */
} Tdim;

typedef struct {
	int             rows;
	int             cols;
	int            *rowy;
	int            *colx;
} Tarray;

struct Tgraph;
struct Tgraph {			/* the order of fields is important--see
				 * Tarray */
	struct Tgraph **down;	/* downnodes for sequential chilren */
	Tdim            dim;	/* dimensions of this field */
	Tarray         *array;
	int             children;	/* number of children */
	struct Tgraph  *up;	/* upnode */
	char           *txt;	/* the text. #1 points for a child */
	char           *options;	/* options to pass to draw routine 
					 */
};

typedef enum {S_NOERR, S_WARN, S_ERR} STAT;
STAT SYNTAX_ERR_FLAG;
#endif
