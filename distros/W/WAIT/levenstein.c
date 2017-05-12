/****  Einfache Levenshtein-Distanz (p0=q0=r0=1) ****/
/****  mit Berücksichtigung von Wildcards        ****/
/****  (geschwindigkeitsoptimiertes C-Programm)  ****/
/****  Autor :  Jörg Michael, Hannover           ****/
/****  Datum :  22. Dezember 1993                ****/

/****  modus = ' ': normale Levenshtein-Distanz  ****/
/****  modus = '+': keine Unterscheidung         ****/
/****               Klein-/Großschreibung        ****/
/****  modus = '*': wie '+', aber zusätzlich     ****/
/****               "symmetrisches" Verhalten    ****/
/****               gemäß der im Text beschrie-  ****/
/****               benen Vorformatierung        ****/

#ifdef __cplusplus
extern          "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}

#endif
#define  maxlen  51 
#ifndef strchr
char          *strchr();
# endif

int 
formatierung(char ziel[], char wort[], int n, char modus)
/****  Wandelt "wort" in GROSSschreibung  ****/
/****  um und expandiert Umlaute          ****/
/****  (n = Zeichenzahl von "ziel")       ****/
/****  Zurückgegeben wird: strlen (ziel)  ****/
{
  int             i, k;
  char            c, *s;

  i = 0;
  k = 0;
  while ((c = wort[i++]) != 0 && k < n - 1) {
    if (isupper(c) || isdigit(c)) {
      ziel[k++] = c;
    } else if (islower(c)) {
      ziel[k++] = c - 'a' + 'A';
    } else {
      s = strchr("ÄAEäAEÖOEöOEÜUEüUEßSS", c);
      if (s != NULL) {
	ziel[k++] = *(s + 1);
	if (k < n - 1) {
	  ziel[k++] = *(s + 2);
	}
      } else if (modus == '*' && c != '?') {
/****  Aufeinanderfolgende '*'  ****/
/****  zu einem zusammenziehen  ****/
	if (k == 0 || ziel[k - 1] != '*') {
	  ziel[k++] = '*';
	}
      } else {
	ziel[k++] = c;
      }
    }
  }
  ziel[k] = 0;
  return (k);
}

int 
WLD(wort, muster, modus, limit)
char *wort; 
char *muster; 
char modus; 
int limit;
{
  register int    spmin, p, q, r, lm, lw, d1, d2, i, k, x1, x2, x3;
  char            c, mm[maxlen], ww[maxlen];
  int             d[maxlen];

  if (limit == 0) {
    limit = maxlen;
  }
  if (modus == '+' || modus == '*') {
    lw = formatierung(ww, wort, maxlen, modus);
    lm = formatierung(mm, muster, maxlen, modus);

    if (modus == '*' && lw < lm - 1
	&& strchr(ww, '*') != NULL) {
/****  Wort und Muster tauschen  ****/
      wort = mm;
      muster = ww;
      strcpy(ww + lw, "*");
      i = lw;
      lw = lm;
      lm = i + 1;
/****  Limit neu setzen  ****/
      i = (int) (i / 3);
      if (i < limit) {
	limit = i;
      }
    } else {
      wort = ww;
      muster = mm;
    }
  } else {
    lw = strlen(wort);
    lm = strlen(muster);
    if (lw >= maxlen)
      lw = (maxlen - 1);
    if (lm >= maxlen)
      lm = (maxlen - 1);
  }

/****  Anfangswerte berechnen ****/
  if (*muster == '*') {
    for (k = 0; k <= lw; k++) {
      d[k] = 0;
    }
  } else {
    d[0] = (*muster == 0) ? 0 : 1;
    i = (*muster == '?') ? 0 : 1;
    for (k = 1; k <= lw; k++) {
      if (*muster == *(wort + k - 1)) {
	i = 0;
      }
      d[k] = k - 1 + i;
    }
  }

  spmin = (d[0] == 0 || lw == 0) ? d[0] : d[1];
  if (spmin > limit) {
    return (maxlen);
  }
/****  Distanzmatrix durchrechnen  ****/
  for (i = 2; i <= lm; i++) {
    c = *(muster + i - 1);
    p = (c == '*' || c == '?') ? 0 : 1;
    q = (c == '*') ? 0 : 1;
    r = (c == '*') ? 0 : 1;
    d2 = d[0];
    d[0] = d2 + q;
    spmin = d[0];

    for (k = 1; k <= lw; k++) {
/****  d[k] = Minimum dreier Zahlen  ****/
      d1 = d2;
      d2 = d[k];
      x1 = d1 + ((c == *(wort + k - 1)) ? 0 : p);
      x2 = d2 + q;
      x3 = d[k - 1] + r;

      if (x1 < x2) {
	x2 = x1;
      }
      d[k] = (x2 < x3) ? x2 : x3;

      if (d[k] < spmin) {
	spmin = d[k];
      }
    }

    if (spmin > limit) {
      return (maxlen);
    }
  }
  return ((d[lw] <= limit) ? d[lw] : maxlen);
}
