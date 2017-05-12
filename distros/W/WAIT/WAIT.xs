#define PERL_POLLUTE

/*                               -*- Mode: C -*- 
 * $Basename: WAIT.xs $
 * $Revision: 1.6 $
 * Author          : Ulrich Pfeifer
 * Created On      : Thu Aug 15 18:01:00 1996
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Wed Nov  5 17:01:30 1997
 * Language        : C
 * Update Count    : 106
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
 * 
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "soundex.h"
#include "stemmer.h"
#include "metaphone.h"
#include "levenstein.h"

static unsigned char *lchars = 
	"abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïñòóôõöøùúûüıß";
static unsigned char *uchars = 
	"ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜİß";
static          char *scodes =
        "01230120022455012623010202000000  00000000500000 000002";
static          char *pcodes =
        "01230720022455012683070808000000  00000000500000 000008";
static unsigned char tou[256];
static unsigned char tol[256];
static unsigned char tos[256];
static          char scd[256];
static          char pcd[256];
static unsigned char *nums = "0123456789";

void init_lcuc ()
{
  short i;
  short l = strlen(lchars);

  for(i=0;i<256;i++) {
    tou[i] = (unsigned char)i;
    tol[i] = (unsigned char)i;
    tos[i] = (unsigned char)' ';
    scd[i] = ' ';
    pcd[i] = ' ';
  }
  for (i=0;i<l;i++) {
    tou[lchars[i]] = uchars[i];
    tol[uchars[i]] = lchars[i];
    tos[uchars[i]] = uchars[i];
    tos[lchars[i]] = lchars[i];
    scd[uchars[i]] = scodes[i];
    scd[lchars[i]] = scodes[i];
    pcd[uchars[i]] = pcodes[i];
    pcd[lchars[i]] = pcodes[i];
  }
  for (i=0;i<10;i++) {
    tos[nums[i]] = nums[i];
  }
}

unsigned char ToUpper(c)
     unsigned char c;
{
  return (tou[c]);
}

unsigned char ToLower(c)
     unsigned char c;
{
  return (tol[c]);
}

#define ToUpper(c) (tou[c])
#define ToLower(c) (tol[c])
#define SoundexLen 4      /* length of a soundex code */
#define SoundexKey "Z000" /* default key for soundex code */

bool IsAlpha(c)
     unsigned char c;
{
  return ((bool) scd[c] != ' ');
}

bool IsVowel(c)
     unsigned char c;
{
  return ((bool) scd[c] == '0');
}

static char SCode(c)
unsigned char c;
{
  return (scd[c]);
}

#define IsAlpha(c) (scd[c] != ' ')
#define IsVowel(c) (scd[c] == '0')
#define SCode(c)   (scd[c])

char PCode(c)
unsigned char c;
{
  return (pcd[c]);
}

void SoundexCode (Name, Key)
unsigned char *Name;
unsigned char *Key;
{
  unsigned char LastLetter;
  int  Index;

  /* set default key */
  strcpy(Key, SoundexKey);
  
  /* keep first letter */
  Key[0] = *Name;
  LastLetter = *Name;
  Name++;

  /* scan rest of string */
  for (Index = 1; (Index < SoundexLen) && *Name; Name++)
  {
    /* use only letters */
    if (IsAlpha(*Name))
    {
      /* ignore duplicate successive chars */
      if (LastLetter != *Name)
      {
        /* new LastLetter */
        LastLetter = *Name;

        /* ignore letters with code 0 */
        if (!IsVowel(*Name) && (SCode(*Name) != 0))
        {
          Key[Index] = SCode(*Name);
          Index++;
        }
      }
    }
  }
}

static unsigned char * isolc (s, l)
unsigned char * s;
int l;
{
  int i;
  for (i=0;i<l;i++) {
    s[i] = tol[s[i]];
  }
  return(s);
}

static unsigned char * isouc (s, l)
unsigned char * s;
int l;
{
  int i;

  for (i=0;i<l;i++) {
    s[i] = tou[s[i]];
  }
  return(s);
}

static unsigned char * isotr (s, l)
unsigned char * s;
int l;
{
  int i;

  for (i=0;i<l;i++) {
    s[i] = tos[s[i]];
  }
  return(s);
}

MODULE = WAIT		PACKAGE = WAIT::Filter		

PROTOTYPES: ENABLE

BOOT:
	init_lcuc ();


char *
isolc(word)
	char *	word
CODE:
{
  char *copy;
  ST(0) = sv_mortalcopy(ST(0));
  copy = (char *)SvPV(ST(0),PL_na);
  (void) isolc(copy, (int)PL_na);
}

char *
isouc(word)
	char *	word
CODE:
{
  char *copy;
  ST(0) = sv_mortalcopy(ST(0));
  copy = (char *)SvPV(ST(0),PL_na);
  (void) isouc(copy, (int)PL_na);
}

char *
isotr(word)
	char *	word
CODE:
{
  char *copy;
  ST(0) = sv_mortalcopy(ST(0));
  copy = (char *)SvPV(ST(0),PL_na);
  (void) isotr(copy, (int)PL_na);
}

char *
disolc(word)
	char *	word
CODE:
{
  (void) isolc(word, (int)PL_na);
}

char *
disouc(word)
	char *	word
CODE:
{
  (void) isouc(word, (int)PL_na);
}

char *
disotr(word)
	char *	word
CODE:
{
  (void) isotr(word, (int)PL_na);
}

char *
Soundex(word)
	char *	word
CODE:   
{
  char key[5];
  Soundex (word, key);
  ST(0) = sv_newmortal();
  sv_setpv((SV *) ST(0), key);
}

char *
Phonix (word)
	char *	word
CODE:   
{
  char key[9];
  Phonix (word, key);
  ST(0) = sv_newmortal();
  sv_setpv((SV *) ST(0), key);
}

char *
Stem (word)	
	char *	word
CODE:   
{
  char copy[80];
  strncpy(copy, word, 79);
  if (Stem(copy)) {
    ST(0) = sv_newmortal();
    sv_setpv((SV *) ST(0), copy);
  }
}

char *
Metaphone (word)	
	char *	word
CODE:   
{
  char metaph[80];
  metaph[0] = '\0';
  phonetic(word,metaph,79);
  ST(0) = sv_newmortal();
  sv_setpv((SV *) ST(0), metaph);
}

void
split_pos(ipair)
	SV *	ipair;
PPCODE:
{
  AV *   aipair  = (AV *) SvRV(ipair);
  char * word    = (char *)SvPV(*av_fetch(aipair, 0, 0),PL_na);
  int    offset  = (av_len(aipair)?SvIV(*av_fetch(aipair, 1, 0)):0);
  char * begin   = word;
  SV   * pair[2];

  pair[0] = newSV((STRLEN)20);
  pair[1] = newSV((STRLEN)0);

  while (*word) {
    char * start;
    AV *   apair;
    SV *   ref;
    while (*word && isspace(*word)) word++;
    if (!*word)  break;
    start = word;
    while (*word && !isspace(*word)) word++;
    EXTEND(sp, 1);
    sv_setpvn(pair[0], start, (STRLEN)(word-start));
    sv_setiv(pair[1],offset + start - begin);
    apair   = av_make(2, pair);
    ref     = newRV_inc((SV*) apair);
    SvREFCNT_dec(apair);
    PUSHs(sv_2mortal(ref));
  }
  /* free pair */
  SvREFCNT_dec(pair[0]);
  SvREFCNT_dec(pair[1]);
}

MODULE = WAIT		PACKAGE = WAIT::Table
int
max(left,right=0)
	int	left
	int	right
CODE:
{
  RETVAL = (left>right)?left:right;
  ST(0) = sv_newmortal();
  sv_setiv(ST(0), (IV)RETVAL);
}


MODULE = WAIT		PACKAGE = WAIT::Metric

int
WLD(word,towards,mode=' ',limit=0)
	char *	word
	char *	towards
	char	mode
	int	limit
