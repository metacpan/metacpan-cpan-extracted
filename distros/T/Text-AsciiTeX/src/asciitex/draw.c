/* draw.c: main drawing routines. */

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
#include "parsedef.h"
#include "asciiTeX_struct.h"
#include "utils.h"
#include "frac.h"
#include "sscript.h"
#include "sqrt.h"
#include "ouline.h"
#include "symbols.h"
#include "brace.h"
#include "array.h"
#include "limit.h"

void
drawInternal(char ***screen, struct Tgraph *graph, int x, int y)
{
	int             kid = 0,
	    curx = x,
	    cury = y + (graph->dim.y - 1) - graph->dim.baseline;
	char           *txt = graph->txt;
	while (*txt)
	{
		if (*txt == 1)
		{
			txt++;
			switch ((PRSDEF) * txt)
			{

			case SUPER:
				drawSuperscript(&kid, &curx, &cury, screen,
						graph, txt);
				break;
			case SUB:
				drawSubscript(&kid, &curx, &cury, screen,
					      graph, txt);
				break;
			case FRAC:
				drawFrac(&kid, &curx, &cury, screen,
					 graph);
				break;
			case SQRT:
				drawSqrt(&kid, &curx, &cury, screen,
					 graph);
				break;
			case OVERLINE:
				drawOverl(&kid, &curx, &cury, screen,
					  graph);
				break;
			case UNDERLINE:
				drawUnderl(&kid, &curx, &cury, screen,
					   graph);
				break;
			case LIMIT:
				drawLimit(&kid, &curx, &cury, screen,
					  graph);
				break;
			case BRACES:
				drawBrace(&kid, &curx, &cury, screen,
					  graph);
				break;
			case ARRAY:
				drawArray(&kid, &curx, &cury, screen,
					  graph);
				break;
			case TO:
				drawTo(&kid, &curx, &cury, screen, graph);
				break;
			case LEADSTO:
				drawLeadsto(&kid, &curx, &cury, screen,
					    graph);
				break;
			case SUM:
				drawSum(&kid, &curx, &cury, screen, graph);
				break;
			case PROD:
				drawProd(&kid, &curx, &cury, screen,
					 graph);
				break;
			case INT:
				drawInt(&kid, &curx, &cury, screen, graph);
				break;
			case LCEIL:
				drawLceil(&kid, &curx, &cury, screen,
					  graph);
				break;
			case RCEIL:
				drawRceil(&kid, &curx, &cury, screen,
					  graph);
				break;
			case LFLOOR:
				drawLfloor(&kid, &curx, &cury, screen,
					   graph);
				break;
			case RFLOOR:
				drawRfloor(&kid, &curx, &cury, screen,
					   graph);
				break;
			case OINT:
				drawOint(&kid, &curx, &cury, screen,
					 graph);
				break;
			default:
				fprintf(stderr,
					"I screwed up in draw, this should never happen!\n");
				exit(1);
				break;
			}
		} else
			(*screen)[cury][curx++] = *txt;
		txt++;
	}
}

char          **
draw(struct Tgraph *graph)
{
	char          **screen = malloc(sizeof(char *) * (graph->dim.y + 1));
	int             i,
	                j;
	for (i = 0; i < graph->dim.y; i++)
	{
		screen[i] = malloc((graph->dim.x + 2) * sizeof(char));
		for (j = 0; j < graph->dim.x; j++)
			screen[i][j] = ' ';
		screen[i][graph->dim.x] = 0;
	}
	drawInternal(&screen, graph, 0, 0);
	return screen;
}
