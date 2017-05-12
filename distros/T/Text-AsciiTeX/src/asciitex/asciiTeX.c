/* asciiTeX.c: The eqaution formmating routine. */

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

/*
 * #define DEBUG 
 */
#ifdef DEBUG
#include <mcheck.h>
#endif
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "asciiTeX_struct.h"
#include "draw.h"
#include "dim.h"
#include "utils.h"

char ** messages;
int Nmes;
int Nall;

char **  asciiTeX(char *eq, int ll, int * cols, int * rows)
{
	struct Tgraph  *graph = malloc(sizeof(struct Tgraph));
	char          **screen;
	char           *txt;
	SYNTAX_ERR_FLAG=S_NOERR;
	Nmes=0;
	Nall=10;
	messages=malloc(Nall*sizeof(char *));
	
#ifdef DEBUG
	mtrace();
#endif
	InitGraph(graph);
	eqdim(txt = preparse(eq), graph,ll);
	if (SYNTAX_ERR_FLAG!=S_ERR)
	{
		free(txt);
		screen = draw(graph);
		*rows=graph->dim.y;
		*cols=graph->dim.x;
	}
	else
	{
		(*cols)=-1;
		(*rows)=Nmes;
		return messages;
	}
	dealloc(graph);
	free(graph);
#ifdef DEBUG
	muntrace();
#endif
	return screen;
}
