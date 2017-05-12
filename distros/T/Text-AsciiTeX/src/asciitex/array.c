/* array.c: layout/dimentioning and drawing routines for arrays. */

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
    Original program (eqascii): Przemek Borys <pborys@dione.ids.pl>
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


char           *
findArrayDelimiter(char *txt)
{
	int             len = strlen(txt);
	int             i;
	for (i = 0; i < len; i++)
	{
		if (txt[i] == '\\')
		{
			if (strncmp(txt + i, "\\begin", 6) == 0)	/* skip
									 * nested
									 * * parts 
									 */
				i += 6 + getbegin_endEnd(txt + i + 1) -
				    (txt + i);
		}
		if ((txt[i] == '&') || (txt[i] == '\n'))
			return txt + i;
	}
	return txt + i;		/* no delimiter has been found */
}

int
dimArray(char *found, char **Gpos, Tdim * Our, struct Tgraph *graph)
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
	    		*tmp = getbegin_endEnd(found + 1),
			rowal='c';
	Tdim            out;

	char          **cells = (char **) malloc(sizeof(char *));
	int             ncells = 0;
	int             rows = 0,
	    cols = 0;
	int             curcols = 0;
	int             i,j;

	if (tmp)
		*tmp = 0;
	else
	{
		SyntaxError("Could not find matching \\end in array %s\n", found);
		return 0;
	}

	*gpos = 1;		/* See parsedef.h for the keyword
				 * definitions */
	gpos++;
	*gpos = (char) ARRAY;
	gpos++;
	*gpos = 0;

	newChild(graph);
	/* find the column-alignment argument */
	start = strchr(found+6+7, '{');
	if (start)
		end = findClosingBrace(start + 1);
	if (!start || !end || (end - start < 2))
	{
		SyntaxError("Usage: \\begin{array}{alignment} elements \\end{array}\n\tProduces an array.\n");
		return 0;
	}
	if (start - found - 6 - 7 > 0)
	{
		/* search for row alignment */
		if (strstr(found+6+7, "[t]"))
			rowal='t';
		else if (strstr(found+6+7, "[b]"))
			rowal='b';
		else if (strstr(found+6+7, "[c]"))
			rowal='c';
		else
			SyntaxWarning("Warning spurious characters ignored in \\array\n");
	}

	*end = 0;
	i=1;
	
	graph->down[graph->children - 1]->options = malloc((strlen(start)+1)*sizeof(char));
	j=0;
	while(start[i])
	{
		switch (start[i])
		{
		case 'l':
		case 'c':
		case 'r':
			/* put char in options */
			graph->down[graph->children - 1]->options[j] = start[i];
			j++;
		case ' ':
			/*ignore*/
			break;
		default:
			SyntaxError("Ill formatted alignment string\n");
			return 0;
		
		}
		i++;
	}
	graph->down[graph->children - 1]->options[j] = '\0';
	cols=j;
	
	*end = '}';
	
	start=end + 1;
	while (1)
	{
		end = findArrayDelimiter(start);
		cells =
		    (char **) realloc(cells,
				      (ncells + 1) * (sizeof(char *)));
		cells[ncells] = (char *) malloc(end - start + 1);
		strncpy(cells[ncells], start, end - start);
		cells[ncells][end - start] = 0;	/* terminate the string */
		ncells++;
		if (*end == '&')
		{
			start = end + 1;
			curcols++;
		} else if (*end == '\n')
		{
			curcols++;
			start = end + 1;
			if ((cols != 0) && (curcols != cols))
			{
				SyntaxError("Bad number of collumns in array\n");
				exit(1);
			}
			cols = curcols;
			curcols = 0;
			rows++;
		} else if (*end == 0)
			break;
	}
	if (curcols)
		rows++;
	if (!cols) /*there was only one line without endline */
		cols++;
	

#define Array (graph->down[graph->children-1])
	Array->array = malloc(sizeof(Tarray));
	Array->array->rows = rows;
	Array->array->cols = cols;
	Array->array->rowy = (int *) calloc(rows, sizeof(int));
	Array->array->colx = (int *) calloc(cols, sizeof(int));
	for (i = 0; i < ncells; i++)
	{
		int             whichrow = i / cols;
		int             whichcol = i - whichrow * cols;
		out = dim(cells[i], newChild(Array));
		if (out.x > Array->array->colx[whichcol])
			Array->array->colx[whichcol] = out.x;
		if (out.y > Array->array->rowy[whichrow])
			Array->array->rowy[whichrow] = out.y;
		free(cells[i]);
	}
	free(cells);
	Array->dim.x = 0;
	for (i = 0; i < cols; i++)
		Array->dim.x += Array->array->colx[i];
	Array->dim.y = 0;
	for (i = 0; i < rows; i++)
		Array->dim.y += Array->array->rowy[i];

	Array->dim.y += Array->array->rows - 1;
	Array->dim.x += Array->array->cols - 1;
	
	switch(rowal)
	{
		case 'b':
			Array->dim.baseline = 0;
			break;
		case 't':
			Array->dim.baseline = Array->dim.y-1;
			break;
		default:
		case 'c':
			Array->dim.baseline = Array->dim.y / 2;
			break;
	}
			
			

	our.x += Array->dim.x;
	if (our.baseline < Array->dim.baseline)
	{
		our.y += Array->dim.baseline - our.baseline;
		our.baseline = Array->dim.baseline;
	}
	if (our.y < Array->dim.y)
		our.y = Array->dim.y;

#undef Array
	*tmp = '\\';		/* restore original value */
	return (tmp + 3 + 7) - found;
#undef gpos
#undef our
}

void
drawArray(int *Kid, int *Curx, int *Cury, char ***screen,
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
#define Array (graph->down[kid])
	int             cury =
	    (*Cury) - ((Array->dim.y - 1) - Array->dim.baseline);
	int             x = 0,
	    y = 0,
	    curitem = 0, xx, yy;
	int             i,
	                j;
	
	
	for (i = 0; i < Array->array->rows; i++)
	{
		for (j = 0; j < Array->array->cols; j++)
		{
			
			yy = cury + y + (Array->array->rowy[i] - Array->down[curitem]->dim.y + 1) / 2;
			
			switch(graph->down[kid]->options[j])
			{
			/* compute current c position (column alignment) */
			case 'l':
				/* left */
				xx=curx + x;
				break;
			case 'r':
				/* right */
				xx=curx + x + (Array->array->colx[j] - Array->down[curitem]->dim.x);
				break;
			case 'c':
				/* center */
				xx=curx + x + (Array->array->colx[j] - Array->down[curitem]->dim.x) / 2;
				break;
			default:
				break;				
			}
			drawInternal(screen, Array->down[curitem], xx,	yy);
			curitem++;
			x += Array->array->colx[j];
			x++;
		}
		y += Array->array->rowy[i];
		y++;
		x = 0;
	}

	curx += Array->dim.x;
	kid++;
#undef Array
}
