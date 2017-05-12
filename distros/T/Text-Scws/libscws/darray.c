/**
 * @file xdict.c (dictionary query)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: darray.c,v 1.1.1.1 2007/06/05 04:19:45 hightman Exp $
 */

#include "darray.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void **darray_new(int row, int col, int size)
{	
	void **arr;

	arr = (void **) malloc(sizeof(void *) * row + size * row * col);
	if (arr != NULL)
	{
		void *head;

		head = (void *) arr + sizeof(void *) * row;
		memset(arr, 0, sizeof(void *) * row + size * row * col);
		while (row--)		
			arr[row] = head + size * row * col;		
	}
	return arr;
}

void darray_free(void **arr)
{
	if (arr != NULL)
		free(arr);	
}

