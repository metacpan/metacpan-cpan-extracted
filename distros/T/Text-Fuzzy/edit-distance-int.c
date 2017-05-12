#line 2 "edit-distance.c.tmpl"
/* For INT_MAX/INT_MIN */
#include <limits.h>
/* For malloc. */
#include <stdlib.h>

#include "config.h"
#include "text-fuzzy.h"
#include "edit-distance-int.h"
#line 1 "declaration"
int distance_int (
                    text_fuzzy_t * tf)

{
#line 97 "edit-distance.c.tmpl"




#line 108 "edit-distance.c.tmpl"
    const unsigned int * word1 = (const unsigned int *) tf->b.unicode;
    int len1 = tf->b.ulength;
    const unsigned int * word2 = (const unsigned int *) tf->text.unicode;
    int len2 = tf->text.ulength;

#line 207 "edit-distance.c.tmpl"

    /* Matrix is the dynamic programming matrix. We economize on space
       by having only two columns. */

#ifdef __GNUC__
    int matrix[2][len2 + 1];
#else
    int * matrix[2];
    int d;
#endif
    int i;
    int j;
    int large_value;

#line 223 "edit-distance.c.tmpl"
    int max;

    max = tf->max_distance;
#line 228 "edit-distance.c.tmpl"

#ifndef __GNUC__
    for (i = 0; i < 2; i++) {
	matrix[i] = calloc (len2 + 1, sizeof (int));
    }
#endif

    /*
      Initialize the 0 row of "matrix".

        0  
        1  
        2  
        3  

     */

    if (max != NO_MAX_DISTANCE) {
        large_value = max + 1;
    }
    else {
        if (len2 > len1) {
            large_value = len2;
        }
        else {
            large_value = len1;
        }
    }

    for (j = 0; j <= len2; j++) {
        matrix[0][j] = j;
    }

    /* Loop over column. */
    for (i = 1; i <= len1; i++) {
        unsigned int c1;
        /* The first value to consider of the ith column. */
        int min_j;
        /* The last value to consider of the ith column. */
        int max_j;
        /* The smallest value of the matrix in the ith column. */
        int col_min;
        /* The next column of the matrix to fill in. */
        int next;
        /* The previously-filled-in column of the matrix. */
        int prev;

        c1 = word1[i-1];
        min_j = 1;
        max_j = len2;
        if (max != NO_MAX_DISTANCE) {
            if (i > max) {
                min_j = i - max;
            }
            if (len2 > max + i) {
                max_j = max + i;
            }
        }
        col_min = INT_MAX;
        next = i % 2;
        if (next == 1) {
            prev = 0;
        }
        else {
            prev = 1;
        }
        matrix[next][0] = i;
        /* Loop over rows. */
        for (j = 1; j <= len2; j++) {
            if (j < min_j || j > max_j) {
                /* Put a large value in there. */
                matrix[next][j] = large_value;
            }
            else {
                unsigned int c2;

                c2 = word2[j-1];
                if (c1 == c2) {
                    /* The character at position i in word1 is the same as
                       the character at position j in word2. */
                    matrix[next][j] = matrix[prev][j-1];

                }
                else {
                    /* The character at position i in word1 is not the
                       same as the character at position j in word2, so
                       work out what the minimum cost for getting to cell
                       i, j is. */
                    int delete;
                    int insert;
                    int substitute;
                    int minimum;

                    delete = matrix[prev][j] + 1;
                    insert = matrix[next][j-1] + 1;
                    substitute = matrix[prev][j-1] + 1;
                    minimum = delete;
                    if (insert < minimum) {
                        minimum = insert;
                    }
                    if (substitute < minimum) {
                        minimum = substitute;
                    }
                    matrix[next][j] = minimum;
                }
            }
            /* Find the minimum value in the ith column. */
            if (matrix[next][j] < col_min) {
                col_min = matrix[next][j];
            }
        }
        if (max != NO_MAX_DISTANCE) {
            if (col_min > max) {
                /* All the elements of the ith column are greater than the
                   maximum, so no match less than or equal to max can be
                   found by looking at succeeding columns. */

#ifndef __GNUC__
		for (i = 0; i < 2; i++) {
		    free (matrix[i]);
		}
#endif
                return large_value;
            }
        }
    }
#ifdef __GNUC__

    return matrix[len1 % 2][len2];

#else
    d = matrix[len1 % 2][len2];

    for (i = 0; i < 2; i++) {
	free (matrix[i]);
    }

    return d;
#endif

#line 370 "edit-distance.c.tmpl"
}

