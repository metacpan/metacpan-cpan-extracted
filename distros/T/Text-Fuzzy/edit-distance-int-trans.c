#line 2 "edit-distance.c.tmpl"
#include <stdio.h>
/* For INT_MAX/INT_MIN */
#include <limits.h>
/* For malloc. */
#include <stdlib.h>

#include "config.h"
#include "text-fuzzy.h"
#include "edit-distance-int-trans.h"
#line 13 "edit-distance.c.tmpl"


/* Our unsorted dictionary linked list.       */

struct dictionary {
    unsigned int key;    /* the character        */
    unsigned int value;  /* character occurance  */
    struct dictionary* next;
};

typedef struct dictionary item;

/* http://ppm4.activestate.com/sun4-solaris-64/5.12/1200/B/BK/BKB/Text-Fuzzy-0.11.d/log-20130328T025706.txt */

#ifdef __GNUC__
#define INLINE inline
#else
#define INLINE 
#endif

static INLINE item * push (unsigned int key, item * curr)
{
    item * head;
    head = malloc (sizeof (item));   
    head->key = key;
    head->value = 0;
    head->next = curr;
    return head;
}

static INLINE item * find (item * head, unsigned int key)
{
    item * iterator = head;
    while (iterator) {
	if (iterator->key == key){
	    return iterator;
	}
	iterator = iterator->next;
    }
    return NULL;
}

/* find & push in 1 function (sperg optimization) */

static INLINE item * uniquePush (item * head, unsigned int key)
{
    item * iterator = head;

    while(iterator){
	if(iterator->key == key){
	    return head;
	}
	iterator = iterator->next;
    }
    return push(key,head); 
}

/* Free the memory associated with "head". */

static void dict_free (item * head)
{
    item * iterator = head;
    while(iterator){
	item * temp = iterator;
	iterator = iterator->next;
	free(temp);
    }
    
    head = NULL;
}

static int minimum (int a, int b)
{
    if (a > b) {
	return b;
    }
    return a;
}


#line 1 "declaration"
int distance_int_trans (
                    text_fuzzy_t * tf)

{
#line 98 "edit-distance.c.tmpl"




#line 109 "edit-distance.c.tmpl"
    const unsigned int * word1 = (const unsigned int *) tf->b.unicode;
    int len1 = tf->b.ulength;
    const unsigned int * word2 = (const unsigned int *) tf->text.unicode;
    int len2 = tf->text.ulength;


    /* keep track of dictionary linked list position */

    item *head = NULL;

    unsigned int swapScore,targetCharCount,i;
    unsigned int score_ceil = len1 + len2;
#ifdef __GNUC__
    unsigned int matrix[len1 + 2][len2 + 2];
#else
    unsigned int ** matrix;
    int d;
#endif

#ifndef __GNUC__
    matrix = calloc (len1 + 2, sizeof (unsigned int *));
    for (i = 0; i < len1 + 2; i++) {
	matrix[i] = calloc (len2 + 2, sizeof (unsigned int));
    }
#endif

    if (len1 == 0) {
	return len2;
    }
    if (len2 == 0) {
	return len1;
    }
 
    /* intialize matrix start values */

    matrix[0][0] = score_ceil;  
    matrix[1][0] = score_ceil;
    matrix[0][1] = score_ceil;
    matrix[1][1] = 0;

    head = uniquePush (uniquePush (head, word1[0]), word2[0]);

    for (i = 1; i <= len1; i++) { 
	int swapCount;
	int j;

	head = uniquePush (head, word1[i]);
	matrix[i+1][1] = i;
	matrix[i+1][0] = score_ceil;
	
	swapCount = 0;

	for (j = 1; j <= len2; j++){
	    if (i == 1) {
		/* only initialize on the first pass     */
		/* optimized over 2 additional for loops */
		head = uniquePush (head, word2[j]);
		matrix[1][j + 1] = j;
		matrix[0][j + 1] = score_ceil;
	    }

	    targetCharCount = find (head, word2[j-1])->value;

	    swapScore = matrix[targetCharCount][swapCount] + i - targetCharCount - 1 + j - swapCount;
	    
	    if(word1[i-1] != word2[j-1]){      
		matrix[i+1][j + 1] = minimum(swapScore,(minimum(matrix[i][j], minimum(matrix[i+1][j], matrix[i][j + 1])) + 1));
	    }
	    else{ 
		swapCount = j;
		matrix[i+1][j + 1] = minimum (matrix[i][j], swapScore);
	    } 
	}
	
	find (head, word1[i-1])->value = i;
    }

    dict_free (head);

#ifdef __GNUC__

    return matrix[len1 + 1][len2 + 1];

#else

    d = matrix[len1 + 1][len2 + 1];

    for (i = 0; i < len1 + 2; i++) {
	free (matrix[i]);
    }
    free (matrix);

    return d;

#endif

#line 371 "edit-distance.c.tmpl"
}

