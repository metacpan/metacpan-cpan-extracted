#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* convert a hex string to an array of ints */

int*
hex_to_array(str)
    char* str;
{
  int *a;
  int i, j, n, v;

  n = strlen(str) / 8;
  New(0, a, n, int);
  for (i = 0; i < n; i++) {
    v = 0;
    for (j = 0; j < 8; j++) {
      v = v << 4;
      if (str[i*8 + j] >= 'a') {
	v = v + str[i*8 + j] - 'a' + 10;
      } else {
	v = v + str[i*8 + j] - '0';
      }
    }
    a[i] = v;
  }
  return(a);
}


/* Pack an array of ints into a hex string */

char*
array_to_hex(a, n)
    int* a;
    int n;
{
  char *res;
  char s[9];
  int i;

  New(0, res, n * 8 + 1, char);
  res[0] = 0;
  for (i = 0; i < n; i++) {
    sprintf(s, "%08x", a[i]);
    strcat(res, s);
  }
  return(res);
}


char*
reflow_trial(optimum_c, maximum, wordcount,
	     penaltylimit, semantic, shortlast,
	     word_len_c, space_len_c, extra_c,
	     result)
    int   maximum, wordcount, penaltylimit, semantic, shortlast;
    char  *optimum_c, *word_len_c, *space_len_c, *extra_c;
    char  *result;
{
    int   *optimum, *word_len, *space_len, *extra;

    int   *linkbreak, *totalpenalty, *best_linkbreak;
    int   lastbreak, i, j, k, interval, penalty, bestsofar;
    int   best_lastbreak, opt;
    char  *best_linkbreak_c;
    int   opts, ii, count;
    int   best = penaltylimit * 21;

    optimum = hex_to_array(optimum_c);
    word_len = hex_to_array(word_len_c);
    space_len = hex_to_array(space_len_c);
    extra = hex_to_array(extra_c);

    count = wordcount * sizeof(int);
    New(0, linkbreak, count, int);
    New(0, totalpenalty, count, int);
    New(0, best_linkbreak, count, int);

  /* Keep gcc -Wall happy: */
  best_lastbreak = 0;

  /* size of optimum array: */
  opts = strlen(optimum_c) / 8;

  for (i = 0; i < opts; i++) {
    opt = optimum[i];
    for (j = 0; j < wordcount; j++) {
      interval = 0;
      totalpenalty[j] = penaltylimit * 2;
      for (k = j; k >= 0; k--) {
	interval += word_len[k];
	if ((k < j) && ((interval > opt + 10)
			  || (interval >= maximum))) {
	  break;
	}
	penalty = (interval - opt) * (interval - opt);
	interval += space_len[k];
	if (k > 0) {
	  penalty += totalpenalty[k-1];
	}
	penalty -= (extra[j] * semantic)/2;
	if (penalty < totalpenalty[j]) {
	  totalpenalty[j] = penalty;
	  linkbreak[j] = k-1;
	}
      }
    }
    interval = 0;
    bestsofar = penaltylimit * 20;
    lastbreak = wordcount-2;
    /* Pick a break for the last line which gives */
    /* the least penalties for previous lines: */
    for (k = wordcount-2; k >= -1; k--) {
      interval += word_len[k+1];
      if ((interval > opt + 10) || (interval > maximum)) {
	break;
      }
      if (interval > opt) {
	penalty = (interval - opt) * (interval - opt);
      } else {
	penalty = 0;
      }
      interval += space_len[k+1];
      if (k >= 0) {
	penalty += totalpenalty[k];
      }
      if (wordcount - k - 1 <= 2) {
	penalty += shortlast * semantic;
      }
      if (penalty <= bestsofar) {
	bestsofar = penalty;
	lastbreak = k;
      }
    }
    /* Save these breaks if they are an improvement: */
    if (bestsofar < best) {
      best_lastbreak = lastbreak;
      for (ii = 0; ii < wordcount; ii++) {
	best_linkbreak[ii] = linkbreak[ii];
      }
      best = bestsofar;
    }
  }

  /* Return the best breaks, */
  /* ie return the array ($best_lastbreak, @best_linkbreak) as a hex string */
  best_linkbreak_c = array_to_hex(best_linkbreak, wordcount);
  sprintf(result, "%08x", best_lastbreak);
  strcat(result, best_linkbreak_c);

  Safefree(optimum);
  Safefree(word_len);
  Safefree(space_len);
  Safefree(extra);
  Safefree(linkbreak);
  Safefree(totalpenalty);
  Safefree(best_linkbreak);
  Safefree(best_linkbreak_c);

  return(result);  
}



MODULE = Text::Reflow		PACKAGE = Text::Reflow		


char *
reflow_trial(optimum, maximum, wordcount, \
	     penaltylimit, semantic, shortlast, \
	     word_len, space_len, extra, result)
    int   maximum
    int   wordcount
    int   penaltylimit
    int   semantic
    int   shortlast
    char* optimum
    char* word_len
    char* space_len
    char* extra
    char* result
    PROTOTYPE: $$$$$$$$$$
  OUTPUT:
    result


