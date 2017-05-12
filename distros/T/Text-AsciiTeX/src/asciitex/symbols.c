/* symbol.c: layout/dimentioning and drawing routines for symbols (things 
   that do not resize). */

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

#include <string.h>
#include "parsedef.h"
#include "utils.h"
#include "asciiTeX_struct.h"
#include "dim.h"
/*
 * all non adaptive symbols here 
 */
/*
 * integral symbol (it has a constant size) 
 */
int
dimInt(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) INT;
	gpos++;
	*gpos = 0;
	our.x += 4;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 3)
		our.y = 3 + our.baseline;
	return 3;

#undef gpos
#undef our
}

void
drawInt(int *Kid, int *Curx, int *Cury, char ***screen,
	struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury - 2][curx + 2] = '_';
	(*screen)[cury - 1][curx + 1] = '/';
	(*screen)[cury][curx + 1] = '|';
	(*screen)[cury + 1][curx + 1] = '/';
	(*screen)[cury + 1][curx] = '_';
	curx += 4;
}

/*
 * closed path integral 
 */
int
dimOint(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) OINT;
	gpos++;
	*gpos = 0;
	our.x += 4;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 3)
		our.y = 3 + our.baseline;
	return 4;

#undef gpos
#undef our
}

void
drawOint(int *Kid, int *Curx, int *Cury, char ***screen,
	 struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury - 2][curx + 2] = '_';
	(*screen)[cury - 1][curx + 1] = '/';
	(*screen)[cury][curx + 1] = 'O';
	(*screen)[cury + 1][curx + 1] = '/';
	(*screen)[cury + 1][curx] = '_';
	curx += 4;
}

/*
 * product sign 
 */
int
dimProd(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) PROD;
	gpos++;
	*gpos = 0;
	our.x += 4;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 2)
		our.y++;
	return 4;

#undef gpos
#undef our
}

void
drawProd(int *Kid, int *Curx, int *Cury, char ***screen,
	 struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury - 1][curx] = '_';
	(*screen)[cury - 1][curx + 1] = '_';
	(*screen)[cury - 1][curx + 2] = '_';
	(*screen)[cury][curx] = '|';
	(*screen)[cury][curx + 2] = '|';
	(*screen)[cury + 1][curx] = '|';
	(*screen)[cury + 1][curx + 2] = '|';
	curx += 4;
}

/*
 * sum sign 
 */
int
dimSum(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) SUM;
	gpos++;
	*gpos = 0;
	our.x += 4;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 2)
		our.y++;
	return 3;

#undef gpos
#undef our
}

void
drawSum(int *Kid, int *Curx, int *Cury, char ***screen,
	struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury - 1][curx] = ' ';
	(*screen)[cury - 1][curx + 1] = '_';
	(*screen)[cury - 1][curx + 2] = '_';
	(*screen)[cury][curx] = '\\';
	(*screen)[cury + 1][curx] = '/';
	(*screen)[cury + 1][curx + 1] = '_';
	(*screen)[cury + 1][curx + 2] = '_';
	curx += 4;
}

/*
 * to sign -> 
 */

int
dimTo(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) TO;
	gpos++;
	*gpos = 0;
	our.x += 2;
	return 2;

#undef gpos
#undef our
}

void
drawTo(int *Kid, int *Curx, int *Cury, char ***screen,
       struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury][curx++] = '-';
	(*screen)[cury][curx++] = '>';
}

int
dimLeadsto(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) LEADSTO;
	gpos++;
	*gpos = 0;
	our.x += 2;
	return 7;

#undef gpos
#undef our
}

void
drawLeadsto(int *Kid, int *Curx, int *Cury, char ***screen,
	    struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury][curx++] = '~';
	(*screen)[cury][curx++] = '>';
}

int
dimLceil(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) LCEIL;
	gpos++;
	*gpos = 0;
	our.x += 2;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 2)
		our.y = 2 + our.baseline;
	return 5;

#undef gpos
#undef our
}

void
drawLceil(int *Kid, int *Curx, int *Cury, char ***screen,
	  struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury][curx++] = '|';
	(*screen)[cury - 1][curx++] = '_';
}

int
dimRceil(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) RCEIL;
	gpos++;
	*gpos = 0;
	our.x += 2;
	if (our.baseline == 0)
	{
		our.baseline++;
		our.y++;
	}
	if (our.y - our.baseline < 2)
		our.y = 2 + our.baseline;
	return 5;

#undef gpos
#undef our
}

void
drawRceil(int *Kid, int *Curx, int *Cury, char ***screen,
	  struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury - 1][curx++] = '_';
	(*screen)[cury][curx++] = '|';
}

int
dimLfloor(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) LFLOOR;
	gpos++;
	*gpos = 0;
	our.x += 2;
	return 6;

#undef gpos
#undef our
}

void
drawLfloor(int *Kid, int *Curx, int *Cury, char ***screen,
	   struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury][curx++] = '|';
	(*screen)[cury][curx++] = '_';
}

int
dimRfloor(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
/*
The dimXxx routines all have the forllowing arguments:
found		--	Pointer to a sting containing the remaining part of the equation
Gpos		--	Pointer to a string which will contain the part of the equation 
			relevant to the current parent with flags to indicate which drawing 
			routines to use.
Our		--	dimention of the parent
graph		--	The parent
The routines returns the number of characters it used of the found vector.
*/
{
#define gpos (*Gpos)
#define our (*Our)

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) RFLOOR;
	gpos++;
	*gpos = 0;
	our.x += 2;
	return 6;

#undef gpos
#undef our
}

void
drawRfloor(int *Kid, int *Curx, int *Cury, char ***screen,
	   struct Tgraph *graph)
/*
The drawXxx routines all have the forllowing arguments:
Kid		--	Ineger index of the current child
Curx		--	Current x position in the 2D character field
Cury		--	Current y position in the 2D character field
screen		--	pointer to the 2D character field
graph		--	The parent
*/
{
#define kid (*Kid)
#define curx (*Curx)
#define cury (*Cury)
	(*screen)[cury][curx++] = '_';
	(*screen)[cury][curx++] = '|';
}
