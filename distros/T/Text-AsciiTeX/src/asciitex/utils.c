/* utils.c: utillities for asciiTeX. */

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
#include <stdarg.h>
#include "asciiTeX_struct.h"
#include "utils.h"

void SyntaxError(char *format_str, ...)
/* Routine to be used to indicate syntax errors. Raises the syntax error flag */ 
{
      	va_list ap;
      	va_start (ap, format_str);
	/*asprintf (&messages[Nmes++],format_str, ap); */
	/*messages[Nmes++]=g_strdup_printf(format_str, ap);*/
	messages[Nmes]=malloc(200*sizeof(char));
	snprintf(messages[Nmes++], 200, format_str, ap);
	if (Nmes==Nall)
	{
		Nall+=10;
		messages=realloc(messages, Nall*sizeof(char *));
	}
	SYNTAX_ERR_FLAG=S_ERR;

}
void SyntaxWarning(char *format_str, ...)
/* Routine to be used to indicate syntax errors. Raises the syntax error flag */ 
{
      	va_list ap;
      	va_start (ap, format_str);
	/*asprintf (&messages[Nmes++],format_str, ap);  */
	/*messages[Nmes++]=g_strdup_printf(format_str, ap);*/
	messages[Nmes]=malloc(200*sizeof(char));
	snprintf(messages[Nmes++], 200, format_str, ap);
	if (Nmes==Nall)
	{
		Nall+=10;
		messages=realloc(messages, Nall*sizeof(char *));
	}
	SYNTAX_ERR_FLAG=S_WARN;

}

char           *
getbegin_endEnd(char *txt)
{
	char           *tmp1 = strstr(txt, "\\begin");
	char           *tmp2 = strstr(txt, "\\end");
	while ((tmp1 < tmp2) && (tmp1 != NULL))
	{
		tmp2 = strstr(tmp2 + 4, "\\end");
		tmp1 = strstr(tmp1 + 6, "\\begin");
	}
	if (tmp2)
		return tmp2;		/* return a pointer to the `\' letter of
				 	* final \end */
	else
	{
		SyntaxError("Missing \\end in getbegin_endEnd\n");
		exit(1);
	}
}

char           *
preparse(char *txt)
{
	char           *result = malloc((strlen(txt) * 3 )*sizeof(char));
	char           *ptr = txt;
	char           *rptr = result;
	while (*ptr)
	{
		if (*ptr == '\n')
		{
			/* endlines are ignored, so is whitespace following */
			/* This is to allow identation in writing the equations */
			do
				ptr++;
			while ((*ptr==' ')||(*ptr=='\t'));
		}
		else
		{
			/* spaces around +/-*= is generally prettier */
			/* We insert spaces as when a line does not fit within the line-length we */
			/* need to insert a break after one of these characters (perhaps this is not */
			/* the most elegant solution). It becomes ugly when, e.g., we want to specify */
			/* the following condition: x > -12 */
			/* In this case breaking lines around the - is undesired and so is inserting */
			/* spaces. The quick and dirty workaround is to escape the - */
			if ((*ptr == '\\') && ((*(ptr+1) != '\\') && (*(ptr+1) != '\0')))
			{
				*rptr = *ptr;
				rptr++;
				ptr++;
				*rptr = *ptr;
				rptr++;
				ptr++;			
			}
			if ((*ptr != '+') && (*ptr != '-') && (*ptr != '/')
			    && (*ptr != '*') && (*ptr != '='))
			{
				*rptr = *ptr;
				rptr++;
				ptr++;
			} else
			{
				*rptr = ' ';
				rptr++;
				*rptr = *ptr;
				rptr++;
				*rptr = ' ';
				rptr++;
				ptr++;
			}
			if ((*(ptr - 1) == '\\') && (*ptr == '\\'))
			{
				/* internally we replace \\ with endline characters as a single endline character is more convenient */
				*(rptr-1)='\n';
				ptr++;			
			}
			if (((*(ptr - 1) == '^') || (*(ptr - 1) == '_'))
			    && (*ptr != '{'))
			{
				if (!(*ptr) && (*(ptr - 2) != '\\'))
				{
					SyntaxError("Premature end of input\n");
					return result;
				}
				if ((*ptr=='^') || (*ptr=='_'))
				{
					SyntaxError("Ill formatter super- of subscript\n");
					return result;
				}
				if ((ptr - 2 < txt)
				    || (*(ptr - 2) != '\\'))
				{
					*rptr = '{';
					rptr++;

					*rptr = *ptr;
					ptr++;
					rptr++;
					if (*(ptr - 1) == '\\')
					{
						while (((*ptr >= 0x41)
							&& (*ptr <= 0x5a))
						       || ((*ptr >= 0x61)
							   && (*ptr <=
							       0x7a))) 
						{	/* while not whitespace or end */
							*rptr = *ptr;
							rptr++;
							ptr++;
						}
					}

					*rptr = '}';
					rptr++;
				}
			}
		}
	}
	*rptr = '\0';
	result = (char *) realloc(result, strlen(result) + 1);
	/*
	 * printf("%s %i\n",result, strlen(result)); 
	 */
	return result;
}

char           *
findClosingBrace(char *txt)
{
	int             opened = 1;
	int             len = strlen(txt);
	int             i;
	for (i = 0; i < len; i++)
	{
		if (txt[i] == '{')
			opened++;
		if (txt[i] == '}')
			opened--;
		if (opened == 0)
			return txt + i;
	}
	SyntaxError("Couldn't find matching brace\n");
	return txt;
}

char           *
findClosingLRBrace(char *txt)
{
/* txt should point to the brace after \left */
	int             opened = 1;
	int             len = strlen(txt);
	int             i;
	char           *lb,
	               *rb,
	                c = (*txt);
	char           *inv = "()[]{}||";

	for (i = 0; i < 7; i += 2)
		if (inv[i] == c)
			c = inv[i + 1];

	lb = malloc(7 * sizeof(char));
	rb = malloc(8 * sizeof(char));

	strncpy(lb, "\\left", 6);
	strncpy(rb, "\\right", 7);

	strncat(lb, txt, 1);
	strncat(rb, &c, 1);

	for (i = 0; i < len; i++)
	{
		if (opened==1)
		{
			/* any left opens */
			/* only the right \right closes */
			if (strncmp(txt + i, lb, 5) == 0)
				opened++;
			else if ((c == '.') && (strncmp(txt + i, "\\right", 6) == 0))
				opened--;
			else if ((strncmp(txt + i, "\\right.", 7) == 0)||(strncmp(txt + i, rb, 7) == 0))
				opened--;
			if (opened == 0)
			{
				free(lb);
				free(rb);
				return txt + i;
			}		
		}
		else
		{
			/* any left opens */
			/* any right closes */
			if (strncmp(txt + i, lb, 5) == 0)
				opened++;
			else if ((strncmp(txt + i, "\\right", 6) == 0))
				opened--;
		}
	}
	free(lb);
	free(rb);
	SyntaxError("Couldn't find matching right brace\n");
	return txt;
}

void  InitGraph(struct Tgraph *graph)
{
	graph->up = NULL;
	graph->down = NULL;
	graph->children = 0;
	graph->options = NULL;
	graph->txt = NULL;
	graph->array = NULL;
}

struct Tgraph  *
newChild(struct Tgraph *graph)
{
	if (graph->children == 0)
		graph->down =
		    (struct Tgraph **) malloc(sizeof(struct Tgraph *));
	else
		graph->down =
		    (struct Tgraph **) realloc(graph->down,
					       sizeof(struct Tgraph **) *
					       (graph->children + 1));
	graph->down[graph->children] =
	    (struct Tgraph *) malloc(sizeof(struct Tgraph));
	graph->down[graph->children]->up = graph;	/* setup the
							 * parent */
	graph->down[graph->children]->options = NULL;
	graph->down[graph->children]->array = NULL;
	graph->down[graph->children]->txt = NULL;
	graph->down[graph->children]->children = 0;
	graph->children++;
	return graph->down[graph->children - 1];
}

void
dealloc_c(struct Tgraph *graph)
{
	int             i;
	for (i = 0; i < graph->children; i++)
	{
		dealloc_c(graph->down[i]);
	}
	if (graph->children)
		free(graph->down);
	if (graph->options)
		free(graph->options);
	if (graph->txt)
		free(graph->txt);
	if (graph->array)
	{
		free(graph->array->rowy);
		free(graph->array->colx);
		free(graph->array);
	}
	free(graph);
}

void
dealloc(struct Tgraph *graph)
{
	int             i;
	for (i = 0; i < graph->children; i++)
	{
		dealloc(graph->down[i]);
		free(graph->down[i]);
	}
	if (graph->children)
		free(graph->down);
	if (graph->options)
		free(graph->options);
	if (graph->txt)
		free(graph->txt);
	if (graph->array)
	{
		free(graph->array->rowy);
		free(graph->array->colx);
		free(graph->array);
	}
}
