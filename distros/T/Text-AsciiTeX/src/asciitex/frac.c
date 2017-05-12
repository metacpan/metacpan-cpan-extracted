/* frac.c: layout/dimentioning and drawing routines for fractions. */

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parsedef.h"
#include "asciiTeX_struct.h"
#include "utils.h"
#include "frac.h"
#include "dim.h"
#include "draw.h"

int
dimFrac(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
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
	Tdim            out;
	char           *start,
	               *end,
	               *tmp;
#define our (*Our)
#define gpos (*Gpos)
	int             height = 0,
	    width = 0;

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) FRAC;
	gpos++;
	*gpos = 0;

	start = strchr(found, '{');
	if (start)
		end = findClosingBrace(start + 1);
	if (!start || !end || (end - start < 2))
	{
		SyntaxError("Usage: \\frac{num}{den}\n\tProduces the fraction num divided by den.\n");
		return 0;
	}
	if (start - found - 5 > 0)
		fprintf(stderr,
			"Warning spurious characters ignores in \\frac\n");

	*end = 0;
	tmp = strdup(start + 1);
	*end = '}';

	out = dim(tmp, newChild(graph));
	free(tmp);
	height += out.y;
	width = out.x;

	start = strchr(end, '{');
	if (start - end - 1 > 0)
		SyntaxWarning("Warning spurious characters ignored in \\frac\n");
	if (start)
		end = findClosingBrace(start + 1);

	if (!start || !end || (end - start < 2))
	{
		SyntaxError("Usage: \\frac{num}{den}\n\tProduces the fraction num divided by den.\n");
		return 0;
	}

	*end = 0;
	tmp = strdup(start + 1);
	*end = '}';
	out = dim(tmp, newChild(graph));
	free(tmp);

	if (out.y > our.baseline)
	{
		our.y += out.y - our.baseline;
		our.baseline = out.y;	/* baseline+(out.y-baseline) */
	}
	if (height > our.y - our.baseline - 1)
	{
		our.y += height - (our.y - our.baseline - 1);
	}
	if (out.x > width)
		our.x += out.x;
	else
		our.x += width;

	if (our.baseline < out.y)
		our.baseline = out.y;
	return end - (found);	/* skip parsed text */
#undef our
#undef gpos
}

void
drawFrac(int *Kid, int *Curx, int *Cury, char ***screen,
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
	int             width = graph->down[kid]->dim.x;
	int             i;
	if (width < graph->down[kid + 1]->dim.x)
		width = graph->down[kid + 1]->dim.x;
	drawInternal(screen, graph->down[kid],
		     curx + width / 2 - (graph->down[kid]->dim.x) / 2,
		     cury - (graph->down[kid]->dim.y));
	drawInternal(screen, graph->down[kid + 1],
		     curx + width / 2 - (graph->down[kid + 1]->dim.x) / 2,
		     cury + 1);
	for (i = 0; i < width; i++)
		(*screen)[cury][curx++] = '-';
	kid += 2;

}
