/* sqrt.c: layout/dimentioning and drawing routines for roots. */

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
#include <stdlib.h>
#include <stdio.h>
#include "parsedef.h"
#include "utils.h"
#include "asciiTeX_struct.h"
#include "dim.h"
#include "draw.h"

int
dimSqrt(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
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
	char           *start,
	               *end,
	               *tmp,
	               *endopt = NULL;
	Tdim            out;

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) SQRT;
	gpos++;
	*gpos = 0;

	start = strchr(found, '{');
	if (!start)
	{
		SyntaxError("Usage: \\sqrt[n]{X}\n\tdraws a root of X, where n is an\n\toptional argument specifying the root\n");
		return 0;
	}
	end = findClosingBrace(start + 1);
	if (end - start < 2)
	{
		SyntaxError("Usage: \\sqrt[n]{X}\n\tdraws a root of X, where n is an\n\toptional argument specifying the root\n");
		return 0;
	}

	*end = 0;
	tmp = strdup(start + 1);
	*end = '}';
	out = dim(tmp, newChild(graph));
	free(tmp);

	tmp = strchr(found, '[');
	if (tmp)
	{
		endopt = strchr(found, ']');		
		if (tmp + 1 < start)
		{
			if ((endopt > start)||(endopt-tmp<2))
			{
				SyntaxError("Usage: \\sqrt[n]{X}\n\tdraws a root of X, where n is an\n\toptional argument specifying the root\n");
				return 0;
			}
			*endopt = '\0';
			graph->down[graph->children - 1]->options =
			    strdup(tmp + 1);
			*endopt = ']';
			our.x +=
			    strlen(graph->
				   down[graph->children - 1]->options) - 1;
		}
	}

	if (start - found - (endopt - tmp + (tmp != 0)) - 5 > 0)
		SyntaxWarning("Warning: Spurious characters ignored in \\sqrt\n");

	out.y++;		/* add the line for top of sqrt drawing */

	if (our.baseline < out.baseline)
	{
		our.y += (out.baseline - our.baseline);
		our.baseline = out.baseline;
	}
	if (our.y - our.baseline < (out.y - out.baseline))
	{
		/*
		 * our.baseline++; 
		 */
		our.y = (out.y - out.baseline) + our.baseline;
	}
	our.x += out.x + our.y;
	return end - (found);
#undef gpos
#undef our
}

void
drawSqrt(int *Kid, int *Curx, int *Cury, char ***screen,
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
	int             i;
	if (graph->down[kid]->options)
	{
		for (i = 0; i < strlen(graph->down[kid]->options); i++)
			(*screen)[cury + graph->down[kid]->dim.baseline -
				  (graph->down[kid]->dim.y - 1) / 2 -
				  1][curx++] =
			    graph->down[kid]->options[i];
		curx--;
	}
	for (i = 0;
	     i <
	     (graph->down[kid]->dim.y -
	      (graph->down[kid]->options != NULL)) / 2 + 1; i++)
		(*screen)[cury + graph->down[kid]->dim.baseline -
			  i][curx] = '|';
	curx++;
	drawInternal(screen, graph->down[kid],
		     curx + graph->down[kid]->dim.y,
		     cury - (graph->down[kid]->dim.y -
			     (graph->down[kid]->dim.baseline + 1)));
	for (i = 0; i < graph->down[kid]->dim.y; i++)
		(*screen)[cury + graph->down[kid]->dim.baseline -
			  i][curx++] = '/';

	for (i = 0; i < graph->down[kid]->dim.x; i++)
		(*screen)[cury - (graph->down[kid]->dim.y) +
			  (graph->down[kid]->dim.baseline)][curx++] = '_';
	kid++;
}
