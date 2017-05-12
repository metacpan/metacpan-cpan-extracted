/* brace.c: layout/dimentioning and drawing routines for braces. */

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
#include "utils.h"
#include "asciiTeX_struct.h"
#include "parsedef.h"
#include "dim.h"
#include "draw.h"

int
dimBrace(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
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
	                c;
	Tdim            out;

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) BRACES;
	gpos++;
	*gpos = 0;

	start = found + 5;
	end = findClosingLRBrace(start);
	c = (*end);
	*end = 0;
	tmp = strdup(found + 6);
	*end = c;
	out = dim(tmp, newChild(graph));
	free(tmp);

	tmp = malloc(sizeof(char) * 3);
	tmp[0] = (*start);
	tmp[1] = (*(end + 6));
	tmp[2] = '\0';

	/*
	 * Store the brace type in the options string of the child 
	 */
	/*
	 * We will use it in the drawing routine 
	 */
	graph->down[graph->children - 1]->options = strdup(tmp);
	free(tmp);

	if ((graph->down[graph->children - 1]->options[0] == '[')
	    && (graph->down[graph->children - 1]->options[1] == ']'))
	{
		if (out.y > 1)
		{
			out.y++;	/* make room for an underscore at
					 * the top */
			out.x += 2;	/* two braces of two chars wide */
		}
	} else if ((graph->down[graph->children - 1]->options[0] == '[')
		   || (graph->down[graph->children - 1]->options[1] ==
		       ']'))
	{
		if (out.y > 1)
		{
			out.y++;	/* make room for an underscore at
					 * the top */
			out.x += 1;	/* one brace is two chars wide */
		}
	}

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

	if ((graph->down[graph->children - 1]->options[0] == '{')
	    || (graph->down[graph->children - 1]->options[1] == '}'))
		our.y += (!(our.y % 2));	/* ensure y is uneven with 
						 * room at the top */

	our.x += out.x + 3;
	return end + 6 - (found);
#undef gpos
#undef our
}

void
drawBrace(int *Kid, int *Curx, int *Cury, char ***screen,
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
	int             low = cury + graph->down[kid]->dim.baseline;
	int             i;
	/*
	 * the options of our child contains the brace type
	 */
	switch (graph->down[kid]->options[0])
	{
	case '(':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx] = '\\';
			for (i = 1; i < graph->down[kid]->dim.y - 1; i++)
				(*screen)[low - i][curx] = '|';
			(*screen)[low - graph->down[kid]->dim.y +
				  1][curx] = '/';
			curx++;
		} else
			(*screen)[cury][curx++] = '(';
		break;
	case '|':
		if (graph->down[kid]->dim.y > 2)
		{
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx] = '|';
			curx++;
		} else
			(*screen)[cury][curx++] = '|';
		break;
	case '[':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx + 1] = '_';
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx] = '|';
			(*screen)[low - graph->down[kid]->dim.y][curx +
								 1] = '_';
			curx += 2;
		} else
			(*screen)[cury][curx++] = '[';
		break;
	case '{':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx] = '\\';
			(*screen)[low -
				  graph->down[kid]->dim.y / 2][curx] = '<';
			for (i = 1;
			     i <
			     graph->down[kid]->dim.y -
			     (graph->down[kid]->dim.y % 2); i++)
				if (!(i == graph->down[kid]->dim.y / 2))
					(*screen)[low - i][curx] = '|';

			(*screen)[low - graph->down[kid]->dim.y +
				  graph->down[kid]->dim.y % 2][curx] = '/';
			curx++;
		} else
			(*screen)[cury + graph->dim.baseline][curx++] =
			    '{';
		break;
	case '.':		/* dummy brace to open or close any type * 
				 * of brace */
		break;
	default:
		if (graph->down[kid]->dim.y > 2)
		{
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx] =
				    graph->down[kid]->options[0];
			curx++;
		} else
			(*screen)[cury][curx++] =
			    *(graph->down[kid]->options);
		break;

	}

	/*
	 * drawInternal (screen, graph->down[kid], curx, cury - (graph->dim.y
	 * - (graph->dim.baseline + 1))); 
	 */
	drawInternal(screen, graph->down[kid], curx,
		     low - graph->down[kid]->dim.y + 1);
	curx += graph->down[kid]->dim.x;

	switch (graph->down[kid]->options[1])
	{
	case ')':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx] = '/';
			for (i = 1; i < graph->down[kid]->dim.y - 1; i++)
				(*screen)[low - i][curx] = '|';
			(*screen)[low - graph->down[kid]->dim.y +
				  1][curx] = '\\';
		} else
			(*screen)[cury][curx] = ')';
		break;
	case '|':
		if (graph->down[kid]->dim.y > 2)
		{
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx] = '|';
		} else
			(*screen)[cury][curx] = '|';
		break;
	case ']':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx] = '_';
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx + 1] = '|';
			(*screen)[low - graph->down[kid]->dim.y][curx] =
			    '_';
			curx++;
		} else
			(*screen)[cury][curx] = ']';
		break;
	case '}':
		if (graph->down[kid]->dim.y > 2)
		{
			(*screen)[low][curx] = '/';
			(*screen)[low -
				  graph->down[kid]->dim.y / 2][curx] = '>';
			for (i = 1;
			     i <
			     graph->down[kid]->dim.y -
			     (graph->down[kid]->dim.y % 2); i++)
				if (!(i == graph->down[kid]->dim.y / 2))
					(*screen)[low - i][curx] = '|';

			(*screen)[low - graph->down[kid]->dim.y +
				  (graph->down[kid]->dim.y % 2)][curx] =
			    '\\';
		} else
			(*screen)[cury][curx] = '}';
		break;
	case '.':		/* dummy brace to open or close any type * 
				 * of brace */
		break;
	default:
		if (graph->down[kid]->dim.y > 2)
		{
			for (i = 0; i < graph->down[kid]->dim.y; i++)
				(*screen)[low - i][curx] =
				    graph->down[kid]->options[1];
		} else
			(*screen)[cury][curx] =
			    graph->down[kid]->options[1];
		break;

	}
	curx++;

	kid++;
}
